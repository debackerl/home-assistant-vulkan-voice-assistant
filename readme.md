This repository hosts a couple files useful to run a Voice Assistant on Home Assistant backed by Vulkan API.

In a nutshell, we integrate the whole system as following:

```mermaid
graph TD;
    HA[Home Assistant]-->|Ollama API| OP;
    HA[Home Assistant]-->|Wyoming protocol| WW;
    HA[Home Assistant]-->|Wyoming protocol| KW;
    OP[Ollama-Proxy]-->LS;
    LS[Llama-Server]-->V;
    WW[Wyoming-Whisper.cpp]-->V;
    V[Vulkan]-->GPU;
    KW[kokoro-wyoming]-->CPU;
```

* *[Llama-Server](https://github.com/ggml-org/llama.cpp)* runs the LLM to generate responses and call tools.
* *[Ollama-proxy](https://github.com/debackerl/ollama-proxy/)* exposes Llama-Server using the same API as Ollama. This is required because Home Assistant doesn't let users change the base URL of their OpenAPI or OpenRouter integrations. Only the Ollama integration lets you do it.
* *[Wyoming-Whisper.cpp](https://github.com/debackerl/wyoming-whisper.cpp/)* implements ASR (Automatic Speech Recognition) using Whisper.cpp. Home Assistant offers Wyoming-Faster-Whisper already, but it doesn't run on Vulkan.
* *[Kokoro-Wyoming-Torch](https://github.com/debackerl/wyoming-kokoro-torch)* It implements the TTS (Text-to-Speech) using Kokoro. It's fast enough to run on a CPU, but you can build your own Docker image to add CUDA or ROCm runtime.

Llama-Server and Wyoming-Whisper.cpp never run at the same time. The ASR always runs first obvisouly, and the whole decoded text will then be fed to the LLM. However, Llama-Server and Wyoming-Piper run concurrently, since the TTS will generate audio while the LLM is generating text.

## Why Vulkan?

1. It's vendor-agnostic, most (all?) GPUs drivers will implement it.
2. The library is generally compact, my container for Radeon is 500 MiB intead of 10+ GiB if I used ROCm.
3. Llama.cpp's implementation on top of Vulkan got as fast, if not faster, than other implementation in spring 2025. See Phoronix's [article](https://www.phoronix.com/review/amd-rocm-7-strix-halo/3).
4. In the case of Radeon, "it just works" using any recent Linux distribution. Some software using ROCm insisted on downloading the DKMS drivers from AMD, which in turn broke the Secure Boot of my system.
5. Ollama doesn't even work nicely on AMD APUs, the community currently needs to use of [fork](https://github.com/rjmalagon/ollama-linux-amd-apu) of Ollama if they whish to use GTT (using "normal" RAM instead of the dedicated VRAM).

## The LLM

GPT OSS 20B is used, by any other LLM supported by Llama.cpp with support for tools can be used. This model is using only 3.6B parameters for each token produced, while using just 12GiB of storage.

## Optimizations

The template of GPT OSS 20B has been hacked to optimize the caching of the prompts. That model starts with an "identity" prompte to tell it what it is, following by a list of built-in tools, then the system prompt, and finally the tools offered by the user. Because Home Assistant puts the current time at the end of the system prompt, the whole description of tools would have to be reevaluated. The hacked template is moving all tools before the system prompt. GPT OSS 20B is still making use of those tools just fine, but it removes about 3 seconds of processing time on my AMD Ryzen AI 9 HX 370 on each new chat.

We use the Q8_0 quantized version of GPT OSS 20B. On the AMD Ryzen AI 9 HX 370, layers quantized in Q8 after faster than F16 or Q4. This speeds up prompt processing by about 10%.

The AMDVLK (user) driver is used since it's still a bit faster than RADV for prompt processing. However, since AMD is now working on RADV instead of AMDVLK, the situation could change.

## Speed

| System                | Model              | Prompt Processing (pp512) | Token Generation (tg128) |
|-----------------------|--------------------|---------------------------|--------------------------|
| AMD Ryzen AI 9 HX 370 | GPT OSS 20B (Q8_0) | 550                       | 25                       |

## Containers

The Dockerfile to build the images below are included in this repository.

| REPOSITORY                        | TAG                       | IMAGE ID       | SIZE (on disk) |
|-----------------------------------|---------------------------|----------------|----------------|
| debackerl/llama-server-vulkan     | b6432-amdvlk-2025.q2.1    | e327b4e19a86   | 443MB          |
| debackerl/ollama-proxy            | be8a17e                   | 6b4581e24a1e   | 28.6MB         |
| debackerl/wyoming-whisper.cpp     | v2.6.1-amdvlk-2025.q2.1   | c7e392c9cea2   | 541MB          |
| debackerl/wyoming-kokoro-torch    | v3.0.0-cpu                | 14dfd64fe888   | 1.53GB         |

## Future

Parakeet TDT 0.6B v3 seems like a much faster, and more accurate ASR model than Whisper. It should be adopted when a Vulkan implementation is ready.

Fish Speech 1.5 has good ratings too, offers more languages, and can sound even more natural, but uses more resources.
