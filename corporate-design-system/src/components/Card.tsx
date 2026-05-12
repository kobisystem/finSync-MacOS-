import type { HTMLAttributes, ReactNode } from "react";
import "./Card.css";

export type CardProps = HTMLAttributes<HTMLDivElement> & {
  active?: boolean;
  elevated?: boolean;
  children: ReactNode;
};

export function Card({ active = false, elevated = false, className = "", children, ...props }: CardProps) {
  return (
    <section
      className={`ds-card ${active ? "ds-card--active" : ""} ${elevated ? "ds-card--elevated" : ""} ${className}`}
      {...props}
    >
      {children}
    </section>
  );
}

export function CardHeader({ className = "", children, ...props }: HTMLAttributes<HTMLDivElement>) {
  return <div className={`ds-card__header ${className}`} {...props}>{children}</div>;
}

export function CardContent({ className = "", children, ...props }: HTMLAttributes<HTMLDivElement>) {
  return <div className={`ds-card__content ${className}`} {...props}>{children}</div>;
}
