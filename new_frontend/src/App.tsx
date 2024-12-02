import { useState } from "react";
import { ConnectButton, useWallet } from "@suiet/wallet-kit";
import "@suiet/wallet-kit/style.css";

import { Box, Flex, Heading, Text } from "@radix-ui/themes";
import { Transaction } from "@mysten/sui/transactions";
import { toast } from "react-toastify";
import SuiLendIcon from "./suilend.svg";
import NaviIcon from "./navi.svg";
import USDCIcon from "./usdc.svg";
import { bcs } from "@mysten/sui/bcs";
import { SuiClient, getFullnodeUrl } from "@mysten/sui/client";

function App() {
  const wallet = useWallet();
  const [amount, setAmount] = useState("");
  const rpcUrl = getFullnodeUrl("mainnet");
  const client = new SuiClient({ url: rpcUrl });

  const handleDeposit = async () => {
    if (!amount || Number(amount) <= 0) {
      toast.error("Please enter a valid amount to deposit.");
      return;
    }

    try {
      const tx = new Transaction();
      if(wallet.address === undefined) {
        throw new Error("Wallet not connected");
      }
      tx.setSender(wallet.address);
      const input = {
        owner: wallet.address,
        coinType:
          "0xdba34672e30cb065b1f93e3ab55318768fd6fef66c15942c9f7cb846e2f900e7::usdc::USDC",
      };

      const all_usdc = await client.getCoins(input);
      if (!all_usdc.data.length) {
        toast.error("No USDC available in your wallet.");
        return;
      }

      const mainObjectId = all_usdc.data[0].coinObjectId;
      const otherObjectIds = all_usdc.data
        .slice(1)
        .map((coin) => coin.coinObjectId);
      
      if(otherObjectIds.length > 0) {
        tx.mergeCoins(mainObjectId, otherObjectIds);
      }

      const [depositToken] = tx.splitCoins(mainObjectId, [
        Number(amount) * 10 ** 6,
      ]);
      
      const [lusdc] = tx.moveCall({
        target:
          "0xfafb681a0f4016576a53d3a90de6fbb13b92e87a824cbec1824fe178d608e59e::lendit::deposit",
        typeArguments: [
          "0xf95b06141ed4a174f239417323bde3f209b972f5930d8521ea38a52aff3a6ddf::suilend::MAIN_POOL",
          "0xdba34672e30cb065b1f93e3ab55318768fd6fef66c15942c9f7cb846e2f900e7::usdc::USDC",
        ],
        arguments: [
          tx.object("0x0000000000000000000000000000000000000000000000000000000000000006"),
          tx.object(depositToken),
          tx.object("0xa0247d82c7eabe746860d47b827174e5906cf0f15e9717f431f201e2319ee624"),
          tx.object("0x2faec094f67109323fc3242437c53b2594a1b77947490cab4b048818d779e1ed"),
          tx.object("0xa3582097b4c57630046c0c49a88bfc6b202a3ec0a9db5597c31765f7563755a8"),
          tx.object("0xbb4e2f4b6205c2e2a2db47aeb4f830796ec7c005f88537ee775986639bc442fe"),
          tx.pure(bcs.U8.serialize(10)),
          tx.object("0x059bccc8046dde1aea32823fee01a41844e082a6ce73fa01aa053ac2daf14583"),
          tx.object("0xaaf735bf83ff564e1b219a0d644de894ef5bdc4b2250b126b2a46dd002331821"),
          tx.object("0xf87a8acb8b81d14307894d12595541a73f19933f88e1326d5be349c7a6f7559c"),
          tx.object("0x1568865ed9a0b5ec414220e8f79b3d04c77acc82358f6e5ae4635687392ffbef"),
          tx.object("0x84030d26d85eaa7035084a057f2f11f701b7e2e4eda87551becbc7c97505ece1"),
          tx.object("0x0daf8bb6527a0bfa956eba5514fc487aaac15b2f05d8e2d419aa728a4f1576b2"),
          tx.pure(bcs.U64.serialize(7)),
          tx.object("0x5dec622733a204ca27f5a90d8c2fad453cc6665186fd5dff13a83d0b6c9027ab"),
        ],
      });

      tx.transferObjects([lusdc], wallet.address);

      const res = await wallet.signAndExecuteTransaction({
        transaction: tx,
      });
      toast.success(`Deposit successful! Transaction Digest: ${res.digest}`);
    } catch (error) {
      const errorMessage = (error as Error).message;
      console.error("Failed to execute transaction:", errorMessage);
      toast.error(`Failed to execute transaction: ${errorMessage}`);
    }
  };

  const handleWithdraw = async () => {
    if (!amount || Number(amount) <= 0) {
      toast.error("Please enter a valid amount to deposit.");
      return;
    }

    try {
      const tx = new Transaction();
      if(wallet.address === undefined) {
        throw new Error("Wallet not connected");
      }
      tx.setSender(wallet.address);
      const input = {
        owner: wallet.address,
        coinType:
          "0xfafb681a0f4016576a53d3a90de6fbb13b92e87a824cbec1824fe178d608e59e::lendit::LENDIT",
      };

      const all_lusdc = await client.getCoins(input);
      if (!all_lusdc.data.length) {
        toast.error("No LUSDC available in your wallet.");
        return;
      }

      const mainObjectId = all_lusdc.data[0].coinObjectId;
      const otherObjectIds = all_lusdc.data
        .slice(1)
        .map((coin) => coin.coinObjectId);
      
      if(otherObjectIds.length > 0) {
        tx.mergeCoins(mainObjectId, otherObjectIds);
      }

      const [withdrawToken] = tx.splitCoins(mainObjectId, [
        Number(amount) * 10 ** 6,
      ]);
      
      const [usdc] = tx.moveCall({
        target:
          "0xfafb681a0f4016576a53d3a90de6fbb13b92e87a824cbec1824fe178d608e59e::lendit::redeem",
        typeArguments: [
          "0xf95b06141ed4a174f239417323bde3f209b972f5930d8521ea38a52aff3a6ddf::suilend::MAIN_POOL",
          "0xdba34672e30cb065b1f93e3ab55318768fd6fef66c15942c9f7cb846e2f900e7::usdc::USDC",
        ],
        arguments: [
          tx.object("0x0000000000000000000000000000000000000000000000000000000000000006"),
          tx.object(withdrawToken),
          tx.object("0xa0247d82c7eabe746860d47b827174e5906cf0f15e9717f431f201e2319ee624"),
          tx.object("0x2faec094f67109323fc3242437c53b2594a1b77947490cab4b048818d779e1ed"),
          tx.object("0xa3582097b4c57630046c0c49a88bfc6b202a3ec0a9db5597c31765f7563755a8"),
          tx.object("0xbb4e2f4b6205c2e2a2db47aeb4f830796ec7c005f88537ee775986639bc442fe"),
          tx.pure(bcs.U8.serialize(10)),
          tx.object("0x059bccc8046dde1aea32823fee01a41844e082a6ce73fa01aa053ac2daf14583"),
          tx.object("0xaaf735bf83ff564e1b219a0d644de894ef5bdc4b2250b126b2a46dd002331821"),
          tx.object("0xf87a8acb8b81d14307894d12595541a73f19933f88e1326d5be349c7a6f7559c"),
          tx.object("0x1568865ed9a0b5ec414220e8f79b3d04c77acc82358f6e5ae4635687392ffbef"),
          tx.object("0x84030d26d85eaa7035084a057f2f11f701b7e2e4eda87551becbc7c97505ece1"),
          tx.object("0x0daf8bb6527a0bfa956eba5514fc487aaac15b2f05d8e2d419aa728a4f1576b2"),
          tx.pure(bcs.U64.serialize(7)),
          tx.object("0x5dec622733a204ca27f5a90d8c2fad453cc6665186fd5dff13a83d0b6c9027ab"),
        ],
      });

      tx.transferObjects([usdc], wallet.address);

      const res = await wallet.signAndExecuteTransaction({
        transaction: tx,
      });
      toast.success(`Deposit successful! Transaction Digest: ${res.digest}`);
    } catch (error) {
      const errorMessage = (error as Error).message;
      console.error("Failed to execute transaction:", errorMessage);
      toast.error(`Failed to execute transaction: ${errorMessage}`);
    }
  };

  return (
    <>
      {/* Top-right Connect Wallet Button */}
      <Flex
        position="absolute"
        top="0"
        right="0"
        px="4"
        py="2"
        justify="end"
        style={{
          borderBottom: "1px solid var(--gray-a2)",
        }}
      >
        <ConnectButton />
      </Flex>

      {/* Centered Lending Widget */}
      <Flex
        style={{ height: "100vh", backgroundColor: "#f9f9f9" }}
        justify="center"
        align="center"
        direction="column"
      >
        <Box
          style={{
            backgroundColor: "white",
            padding: "2rem",
            borderRadius: "12px",
            boxShadow: "0 4px 12px rgba(0, 0, 0, 0.1)",
            width: "350px",
            textAlign: "center",
            border: "1px solid #eee",
          }}
        >
          <Heading size="4" mb="2">
            Lend-It
          </Heading>
          <Text size="2" mb="4" color="gray">
            Maximize your lending rates on Sui
          </Text>
          {wallet ? (
            <>
              {/* Single Input Box */}
              <Box mb="4">
                <Flex align="center" mb="2" justify="start">
                  <img
                    src={USDCIcon}
                    alt="USDC"
                    style={{ width: "20px", marginRight: "10px" }}
                  />
                  <Text size="2">USDC</Text>
                </Flex>
                <input
                  type="number"
                  placeholder="Enter amount"
                  value={amount}
                  onChange={(e) => setAmount(e.target.value)}
                  style={{
                    width: "100%",
                    padding: "0.75rem",
                    border: "1px solid #ddd",
                    borderRadius: "8px",
                  }}
                />
              </Box>

              <Flex justify="center" align="center" direction="column" gap="4">
                {/* Logo Section */}
                <Flex justify="center" align="center" gap="4">
                  <Box>
                    <img
                      src={SuiLendIcon}
                      alt="SUILEND"
                      style={{
                        width: "50px",
                        height: "50px",
                        borderRadius: "50%",
                      }}
                    />
                    <Text size="1" color="gray" align="center">
                      SUILEND
                    </Text>
                  </Box>
                  <Box>
                    <img
                      src={NaviIcon}
                      alt="NAVI"
                      style={{
                        width: "50px",
                        height: "50px",
                        borderRadius: "50%",
                      }}
                    />
                    <Text size="1" color="gray" align="center">
                      NAVI
                    </Text>
                  </Box>
                  <Box>
                    <div
                      style={{
                        width: "50px",
                        height: "50px",
                        backgroundColor: "#f3f3f3",
                        borderRadius: "50%",
                        display: "flex",
                        justifyContent: "center",
                        alignItems: "center",
                      }}
                    />
                    <Text size="1" color="gray" align="center">
                      COMING
                    </Text>
                  </Box>
                  <Box>
                    <div
                      style={{
                        width: "50px",
                        height: "50px",
                        backgroundColor: "#f3f3f3",
                        borderRadius: "50%",
                        display: "flex",
                        justifyContent: "center",
                        alignItems: "center",
                      }}
                    />
                    <Text size="1" color="gray" align="center">
                      SOON
                    </Text>
                  </Box>
                </Flex>

                {/* Button Section */}
                <Flex justify="center" gap="4" mt="4">
                  <button
                    onClick={handleDeposit}
                    style={{
                      padding: "8px 16px",
                      border: "none",
                      borderRadius: "4px",
                      backgroundColor: "#007bff",
                      color: "white",
                      fontSize: "14px",
                      cursor: "pointer",
                    }}
                  >
                    Deposit
                  </button>
                  <button
                    onClick={handleWithdraw}
                    style={{
                      padding: "8px 16px",
                      border: "1px solid #ddd",
                      borderRadius: "4px",
                      backgroundColor: "white",
                      color: "#333",
                      fontSize: "14px",
                      cursor: "pointer",
                    }}
                  >
                    Withdraw
                  </button>
                </Flex>
              </Flex>
            </>
          ) : (
            <button
              style={{
                width: "100%",
                padding: "0.75rem",
                border: "none",
                borderRadius: "8px",
                backgroundColor: "#007bff",
                color: "white",
                fontWeight: "bold",
                cursor: "pointer",
              }}
            >
              Connect Wallet
            </button>
          )}
        </Box>
      </Flex>
    </>
  );
}

export default App;
