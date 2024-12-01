import { ConnectButton, useCurrentAccount } from "@mysten/dapp-kit";
import { Box, Flex, Heading, Text } from "@radix-ui/themes";
import SuiLendIcon from "./suilend.svg";
import NaviIcon from "./navi.svg";
import USDCIcon from "./usdc.svg";

function App() {
  const account = useCurrentAccount();

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
          {account ? (
            <>
              <Box mb="4">
                <Flex align="center" mb="2" justify="start">
                  <img
                    src = {USDCIcon}
                    alt="USDC"
                    style={{ width: "20px", marginRight: "10px" }}
                  />
                  <Text size="2">USDC</Text>
                </Flex>
                <input
                  type="number"
                  placeholder="0.00"
                  style={{
                    width: "100%",
                    padding: "0.75rem",
                    border: "1px solid #ddd",
                    borderRadius: "8px",
                  }}
                />
              </Box>
              <Flex justify="center" align="center" direction="column" gap="16px">
                {/* Logo Section */}
                <Flex justify="center" align="center" gap="16px">
                  <Box>
                    <img
                      src={SuiLendIcon}
                      alt="SUILEND"
                      style={{ width: "50px", height: "50px", borderRadius: "50%" }}
                    />
                    <Text size="1" color="gray" align="center">
                      SUILEND
                    </Text>
                  </Box>
                  <Box>
                    <img
                      src={NaviIcon}
                      alt="NAVI"
                      style={{ width: "50px", height: "50px", borderRadius: "50%" }}
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
                <Flex justify="center" gap="16px" mt="16px">
                <button
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
