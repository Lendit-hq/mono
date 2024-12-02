import React from "react";
import ReactDOM from "react-dom/client";
import "@mysten/dapp-kit/dist/index.css";
import "@radix-ui/themes/styles.css";
import "react-toastify/dist/ReactToastify.css";
import { WalletProvider } from "@suiet/wallet-kit";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { Theme } from "@radix-ui/themes";
import { ToastContainer } from "react-toastify";
import App from "./App.tsx";

const queryClient = new QueryClient();

ReactDOM.createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <Theme appearance="light">
      <QueryClientProvider client={queryClient}>
          <WalletProvider>
            <ToastContainer />
                <App />
          </WalletProvider>
      </QueryClientProvider>
    </Theme>
  </React.StrictMode>,
);
