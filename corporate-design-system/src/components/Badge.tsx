import type { HTMLAttributes, ReactNode } from "react";
import "./Badge.css";

export type BadgeTone = "success" | "neutral" | "warning" | "error";

export type BadgeProps = HTMLAttributes<HTMLSpanElement> & {
  tone?: BadgeTone;
  children: ReactNode;
};

export function Badge({ tone = "neutral", className = "", children, ...props }: BadgeProps) {
  return <span className={`ds-badge ds-badge--${tone} ${className}`} {...props}>{children}</span>;
}
