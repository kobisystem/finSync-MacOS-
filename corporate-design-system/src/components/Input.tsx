import type { InputHTMLAttributes } from "react";
import "./Input.css";

export type InputProps = InputHTMLAttributes<HTMLInputElement> & {
  label?: string;
  hint?: string;
  error?: string;
};

export function Input({ label, hint, error, className = "", id, ...props }: InputProps) {
  const inputId = id ?? label?.toLowerCase().replace(/\s+/g, "-");

  return (
    <label className={`ds-field ${className}`} htmlFor={inputId}>
      {label && <span className="ds-field__label">{label}</span>}
      <input
        id={inputId}
        className={`ds-input ds-focus-ring ${error ? "ds-input--error" : ""}`}
        {...props}
      />
      {(error || hint) && <span className={error ? "ds-field__error" : "ds-field__hint"}>{error || hint}</span>}
    </label>
  );
}
