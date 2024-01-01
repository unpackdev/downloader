pragma solidity ^0.8.20;
import "./ECDSA.sol";
import "./MessageHashUtils.sol";

interface IERC20 {
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);
}

contract Presale {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    IERC20 public token;
    address public owner;
    uint256 public privateStartTime;
    uint256 public publicStartTime;
    uint256 public endTime;
    uint256 public minAmount;
    uint256 public maxAmount;
    uint256 public exchangeRate;
    uint256 public softCap;
    uint256 public hardCap;
    uint256 public totalRaised;
    mapping(address => bool) public isSigner;
    mapping(address => uint256) public contributedAmount;
    mapping(address => bool) public hasClaimedTokens;

    constructor(
        IERC20 _token,
        uint256 _privateStartTime,
        uint256 _publicStartTime,
        uint256 _endTime,
        uint256 _minAmount,
        uint256 _maxAmount,
        uint256 _exchangeRate,
        uint256 _softCap,
        uint256 _hardCap
    ) {
        owner = msg.sender;
        token = _token;
        privateStartTime = _privateStartTime;
        publicStartTime = _publicStartTime;
        endTime = _endTime;
        minAmount = _minAmount;
        maxAmount = _maxAmount;
        exchangeRate = _exchangeRate;
        softCap = _softCap;
        hardCap = _hardCap;
    }

    // only owner can call this function
    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only contract owner can call this function."
        );
        _;
    }

    // contributors can send funds to the contract
    function contribute(bytes memory signature) public payable {
        require(
            block.timestamp >= privateStartTime && block.timestamp <= endTime,
            "Presale has not started or has ended."
        );

        require(
            totalRaised + msg.value <= hardCap,
            "Presale has reached the hard cap."
        );

        if (block.timestamp < publicStartTime) {
            require(verifyWhiteList(signature), "Sender is not whitelisted.");
        }

        uint256 contributeCount = contributedAmount[msg.sender] + msg.value;
        require(
            contributeCount >= minAmount && contributeCount <= maxAmount,
            "Contribution amount is not within the allowed range."
        );

        contributedAmount[msg.sender] += msg.value;
        totalRaised += msg.value;
    }

    // if soft cap is reached, contributors can claim their tokens
    function claimTokens() public {
        require(block.timestamp > endTime, "Presale has not ended yet.");
        require(
            totalRaised >= softCap,
            "Presale has not reached the soft cap."
        );
        require(
            contributedAmount[msg.sender] > 0,
            "No contribution found for the sender."
        );
        require(
            !hasClaimedTokens[msg.sender],
            "Tokens have already been claimed by the sender."
        );

        uint256 tokenAmount = contributedAmount[msg.sender] * exchangeRate;

        token.transfer(msg.sender, tokenAmount);
        hasClaimedTokens[msg.sender] = true;
    }

    // if soft cap is not reached, contributors can claim their funds back
    function refund() public {
        require(block.timestamp > endTime, "Presale has not ended yet.");
        require(
            totalRaised < softCap,
            "Presale has reached the soft cap, no refunds allowed."
        );
        require(
            contributedAmount[msg.sender] > 0,
            "No contribution found for the sender."
        );

        uint256 amount = contributedAmount[msg.sender];
        contributedAmount[msg.sender] = 0;

        payable(msg.sender).transfer(amount);
    }

    // if Presale is successful, owner can withdraw funds
    function withdrawFunds() public onlyOwner {
        require(block.timestamp > endTime, "Presale has not ended yet.");

        uint256 balance = address(this).balance;
        payable(owner).transfer(balance);
    }

    // owner can withdraw tokens
    function withdrawToken(uint256 amount) public onlyOwner {
        require(block.timestamp > endTime, "Presale has not ended yet.");

        token.transfer(owner, amount);
    }

    function setEndTime(uint256 _endTime) public onlyOwner {
        endTime = _endTime;
    }

    function verifyWhiteList(
        bytes memory signature
    ) public view returns (bool) {
        bytes32 messageHash = keccak256(
            abi.encodePacked(
                uint256(block.chainid),
                address(this),
                address(msg.sender)
            )
        );
        return _verifySignature(messageHash, signature) == owner;
    }

    function _verifySignature(
        bytes32 message,
        bytes memory signature
    ) internal pure returns (address) {
        bytes32 hash = message.toEthSignedMessageHash();
        return hash.recover(signature);
    }
}
