// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.6;

import "./ChainlinkClient.sol";
import "./LinkTokenInterface.sol";
import "./Ownable.sol";
import "./InitialYollarStaking.sol";
import "./IApiCaller.sol";
import "./console.sol";

error IncorrectEth();
error TransferFailed();
error NotEnoughLINK();

contract ApiCallerConsumer is ChainlinkClient, IApiCaller, Ownable {
    using Chainlink for Chainlink.Request;
    InitialYollarStaking public receiverContract;

    uint128 public withdrawalFee;
    address private oracle;
    bytes32 private jobId;
    uint256 private fee;
    LinkTokenInterface private link;
    mapping(bytes1 => uint8) private decoder;

    
    constructor() {
        setPublicChainlinkToken();
        setParameters(0.1 ether, 0.00061 ether,    0x514910771AF9Ca656af840dff83E8264EcF986CA, "0d21526754cc4cc3a53f1d4973454adc", 0x049Bd8C3adC3fE7d3Fc2a44541d955A537c2A484);
        // setParameters(0.1 ether, 0.00061 ether, 0xa36085F69e2889c224210F603D836748e7dC0088, "7401f318127148a894c00c292e486ffd", 0xc57B33452b4F7BB189bB5AfaE9cc4aBa1f7a4FD8);
        decoder[bytes1(0x0)] = 0;
        decoder[bytes1(0x30)] = 0;
        decoder[bytes1(0x31)] = 1;
        decoder[bytes1(0x32)] = 2;
        decoder[bytes1(0x33)] = 3;
        decoder[bytes1(0x34)] = 4;
        decoder[bytes1(0x35)] = 5;
        decoder[bytes1(0x36)] = 6;
        decoder[bytes1(0x37)] = 7;
        decoder[bytes1(0x38)] = 8;
        decoder[bytes1(0x39)] = 9;
        decoder[bytes1(0x61)] = 10;
        decoder[bytes1(0x62)] = 11;
        decoder[bytes1(0x63)] = 12;
        decoder[bytes1(0x64)] = 13;
        decoder[bytes1(0x65)] = 14;
        decoder[bytes1(0x66)] = 15;
    }

    /**
     * Create a Chainlink request to retrieve API response, find the target
     * data, then multiply by 1000000000000000000 (to remove decimal places from data).
     */
    function callBackend(address owner_)
        public
        payable
        override
        returns (bytes32 requestId)
    {
        if (msg.value != withdrawalFee) {
            revert IncorrectEth();
        }
        if (link.balanceOf(address(this)) < fee) {
            revert NotEnoughLINK();
        }
        Chainlink.Request memory request = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfill.selector
        );

        // Set the URL to perform the GET request on
        request.add(
            "get",
            string(
                abi.encodePacked(
                    "https://6v56radu08.execute-api.us-east-2.amazonaws.com/Prod/yollar?address=0x",
                    toAsciiString(owner_)
                )
            )
        );

        request.add("path", "value");

        return sendChainlinkRequestTo(oracle, request, fee);
    }

    /**
     *  @dev here is how the 2nd argument works.
     *  1. The backend calcualtes two values: winnings and losses. Both positive and both in ether unit. Meaning that a value of 5 means 5 ether NOT 5*10**8 wei
     *  2. The backend creates a 10 byte value as follows. winnings << 5 * 8 | spending. In other words the first 5 bytes show the winnings and the second 5 bytes show the spnedings.
     *  3. The backend then converts this 10 byte value into a hex string. Which will be come a 20 byte value. Each character represets 4 bits.
     *  4. These 20 bytes are set as the first 20 bytes of the the second input argument.
     *  5. The code code loops through the first 10 bytes and the then the second 10 bytes.
     *     In each iteration, it chooses two hex chararcter and forms a byte from them. To do this, the code uses a decoding table.
     */
    function fulfill(bytes32 requestId_, bytes32 resultsHexString_)
        public
        recordChainlinkFulfillment(requestId_)
    {
        // twoResults = resultsHexString_;
        bytes16 spentByte;
        for (int256 i = 0; i <= 8; i += 2) {
            uint128 upperTmp = decoder[
                bytes1(uint8(resultsHexString_[uint256(i)]))
            ];
            uint128 lowerTmp = decoder[
                bytes1(uint8(resultsHexString_[uint256(i + 1)]))
            ];
            uint128 tmp = (upperTmp << 4) | lowerTmp;
            if (tmp != 0) {
                spentByte =
                    spentByte |
                    (bytes16(tmp) << (uint256(4 - i / 2) * 8));
            }
        }
        uint128 spent = uint128(spentByte) * 10**18;

        bytes16 wonByte;
        for (uint256 i = 10; i <= 18; i += 2) {
            uint128 upperTmp = decoder[
                bytes1(uint8(resultsHexString_[uint256(i)]))
            ];
            uint128 lowerTmp = decoder[
                bytes1(uint8(resultsHexString_[uint256(i + 1)]))
            ];
            uint128 tmp = (upperTmp << 4) | lowerTmp;
            if (tmp != 0) {
                wonByte = wonByte | (bytes16(tmp) << (uint256(9 - i / 2) * 8));
            }
        }
        uint128 won = uint128(wonByte) * 10**18;
        receiverContract.withdrawFinalize(requestId_, spent, won);
    }

    // Implements a withdraw function to avoid locking your LINK in the contract
    function withdrawLink(address payable to, uint256 amount)
        external
        onlyOwner
    {
        link.transfer(to, amount);
    }

    function withdrawEth(address payable to, uint256 amount)
        external
        onlyOwner
    {
        // https://consensys.github.io/smart-contract-best-practices/recommendations/ recommends using this instead of transfer
        (bool success, ) = to.call{value: amount}(""); // solhint-disable-line
        if (!success) {
            revert TransferFailed();
        }
    }

    function setReceiverContract(address _address) public onlyOwner {
        receiverContract = InitialYollarStaking(_address);
    }

    function setParameters(uint128 fee_, uint128 withdrawalFee_, address linkAddress_, bytes32 jobId_, address oracleAddress_) public onlyOwner {
        oracle = oracleAddress_;
        link = LinkTokenInterface(linkAddress_);
        jobId = jobId_;
        fee = fee_;
        withdrawalFee = withdrawalFee_;
    }

    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint256 i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint256(uint160(x)) / (2**(8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = char(hi);
            s[2 * i + 1] = char(lo);
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
}
