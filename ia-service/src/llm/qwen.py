# ia-service/src/llm/qwen.py

import os
import torch
from transformers import AutoTokenizer, AutoModelForCausalLM
from typing import Optional
import logging

logger = logging.getLogger(__name__)

class QwenLLM:
    def __init__(
        self,
        model_name: str = "Qwen/Qwen2.5-0.5B-Instruct",
        device: Optional[str] = None,
        max_length: int = 2048,
        temperature: float = 0.3,  
        top_p: float = 0.9,
    ):
        self.model_name = model_name
        self.max_length = max_length
        self.temperature = temperature
        self.top_p = top_p
        
        if device is None:
            self.device = "cuda" if torch.cuda.is_available() else "cpu"
        else:
            self.device = device
        
        logger.info(f"Chargement du modèle {model_name} sur {self.device}...")
        
        self.tokenizer = AutoTokenizer.from_pretrained(
            model_name,
            trust_remote_code=True,
            padding_side="left",
        )
        
        if self.tokenizer.pad_token is None:
            self.tokenizer.pad_token = self.tokenizer.eos_token
        
        self.model = AutoModelForCausalLM.from_pretrained(
            model_name,
            torch_dtype=torch.float16 if self.device == "cuda" else torch.float32,
            device_map="auto" if self.device == "cuda" else None,
            trust_remote_code=True,
            low_cpu_mem_usage=True,
        )
        
        if self.device == "cpu":
            self.model = self.model.to(self.device)
        
        self.model.eval()
        logger.info(f"Modèle chargé avec succès !")
    
    def generate(
        self,
        prompt: str,
        max_new_tokens: int = 256,  #  Réduire
        temperature: Optional[float] = None,
        top_p: Optional[float] = None,
    ) -> str:
        if max_new_tokens is None:
            max_new_tokens = 256
        
        if temperature is None:
            temperature = self.temperature
        
        if top_p is None:
            top_p = self.top_p
        
        # 👇 FORMAT QWEN INSTRUCT
        messages = [
            {"role": "system", "content": "Tu es un professeur particulier pour des élèves comoriens. Réponds en français, de manière claire et pédagogique. Adapte ton langage au niveau de l'élève."},
            {"role": "user", "content": prompt},
        ]
        
        # Appliquer le template de chat Qwen
        formatted_prompt = self.tokenizer.apply_chat_template(
            messages,
            tokenize=False,
            add_generation_prompt=True,
        )
        
        inputs = self.tokenizer(
            formatted_prompt,
            return_tensors="pt",
            truncation=True,
            max_length=self.max_length,
        ).to(self.device)
        
        with torch.no_grad():
            outputs = self.model.generate(
                **inputs,
                max_new_tokens=max_new_tokens,
                temperature=temperature,
                top_p=top_p,
                do_sample=True,
                pad_token_id=self.tokenizer.eos_token_id,
                repetition_penalty=1.1,
            )
        
        response = self.tokenizer.decode(
            outputs[0][inputs.input_ids.shape[1]:],
            skip_special_tokens=True,
        )
        
        return response.strip()
    
    def chat(self, user_message: str, system_message: Optional[str] = None, **kwargs) -> str:
        if system_message:
            prompt = f"<|im_start|>system\n{system_message}<|im_end|>\n<|im_start|>user\n{user_message}<|im_end|>\n<|im_start|>assistant\n"
        else:
            prompt = f"<|im_start|>user\n{user_message}<|im_end|>\n<|im_start|>assistant\n"
        
        return self.generate(prompt, **kwargs)