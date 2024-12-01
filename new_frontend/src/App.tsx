import { ConnectButton, useCurrentAccount } from "@mysten/dapp-kit";
import { Box, Flex, Heading, Text } from "@radix-ui/themes";

// Import SVGs directly
import SuiLendIcon from "./suilend.svg";
import NaviIcon from "./navi.svg";

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
        style={{ height: "100vh", backgroundColor: "white" }}
        justify="center"
        align="center"
        direction="column"
      >
        <Box
          style={{
            backgroundColor: "white",
            padding: "2rem",
            marginTop: "15rem",
            borderRadius: "10px",
            boxShadow: "0 4px 8px rgba(0, 0, 0, 0.1)",
            width: "700px",
            height: "400px",
            textAlign: "center",
            border: "1px solid #ddd",
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
              <Box mb="2">
                <Text>You’re lending:</Text>
                <input
                  type="number"
                  placeholder="0.00"
                  style={{
                    width: "100%",
                    padding: "0.5rem",
                    marginTop: "0.5rem",
                    border: "1px solid #ddd",
                    borderRadius: "5px",
                  }}
                />
              </Box>
              <Flex justify="center" mt="2">
                <img
                  src={SuiLendIcon}
                  alt="SUILEND"
                  style={{ width: "40px", marginRight: "10px" }}
                />
                <img
                  src={NaviIcon}
                  alt="NAVI"
                  style={{ width: "40px" }}
                />
              </Flex>
            </>
          ) : (
            <Text>Please connect your wallet to proceed</Text>
          )}
        </Box>
      </Flex>
    </>
  );
}

export default App;
