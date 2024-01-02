// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./Ownable.sol";
import "./ECDSA.sol";
import "./ITEARSale.sol";

/**
 * @title TEARSale
 * @custom:website www.descend.gg
 * @notice Sale contract for $TEAR
 */
contract TEARSale is ITEARSale, Ownable {
    using ECDSA for bytes32;

    /// @dev Minimum amount of ETH that can be contributed
    uint256 public minAmount = 0.05 ether;

    /// @dev Maximum amount of ETH that can be contributed
    uint256 public maxAmount = 5 ether;

    /// @dev Mapping of user ID to user information
    mapping(uint256 => User) private _user;

    /// @dev Mapping of user addresses to user IDs
    mapping(address => uint256) private _userIdx;

    /// @dev Total amount of ETH contributed
    uint256 public totalEth;

    /// @dev Total number of users who have contributed
    uint256 public totalUsers;

    /// @dev Maximum amount of ETH that the contract can hold
    uint256 public maxCapacity = 500 ether;

    /// @dev Sale flag
    SaleFlag public saleFlag;

    /// @dev Signer address
    address public signerAddress;

    /// @dev Sets the deployer as the initial owner
    constructor(address signerAddress_) Ownable(msg.sender) {
        setSignerAddress(signerAddress_);
    }

    /// @dev Allows the contract to receive ETH directly and triggers the enter process
    receive() external payable {
        require(saleFlag == SaleFlag.SALE_PUBLIC, "!public");
        _contribute();
    }

    /// @notice Contribute ETH to the sale (public)
    function contribute() public payable {
        require(saleFlag == SaleFlag.SALE_PUBLIC, "!public");
        _contribute();
    }

    /// @notice Contribute ETH to the sale (presale only)
    function presale(bytes calldata signature) public payable {
        require(saleFlag != SaleFlag.SALE_CLOSED, "!presale");
        if (saleFlag == SaleFlag.SALE_PRESALE) {
            bytes32 dataHash = keccak256(abi.encodePacked(msg.sender));
            bytes32 message = ECDSA.toEthSignedMessageHash(dataHash);
            address receivedAddress = ECDSA.recover(message, signature);
            require(
                receivedAddress != address(0) &&
                    receivedAddress == signerAddress,
                "!ineligible"
            );
        }
        _contribute();
    }

    /// @dev Private function to manage contributions, including validation and accounting
    function _contribute() private {
        require(msg.value >= minAmount, "!undermin");
        totalEth += msg.value;
        require(totalEth <= maxCapacity, "!overcap");
        uint256 idx = _userIdx[msg.sender];
        if (idx == 0) {
            idx = ++totalUsers;
        }
        uint256 userTotal = _user[idx].amount + msg.value;
        require(userTotal <= maxAmount, "!overmax");
        _userIdx[msg.sender] = idx;
        _user[idx].amount = userTotal;
        _user[idx].addr = msg.sender;
    }

    /// @dev Allows the owner to withdraw the entire balance of the contract
    function withdraw() public onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success, "!failed");
    }

    /// @dev Allows the owner to withdraw the funds to an address
    function withdrawTo(address dest, uint256 amount) public onlyOwner {
        (bool success, ) = payable(dest).call{value: amount}("");
        require(success, "!failed");
    }

    /// @inheritdoc ITEARSale
    function getUser(uint256 idx) public view returns (User memory) {
        return _user[idx];
    }

    /// @inheritdoc ITEARSale
    function getUserIdx(address user) public view returns (uint256) {
        return _userIdx[user];
    }

    /// @dev Allows the owner to set a new capacity for the contract
    /// @param cap The new capacity in wei
    function setMaxCapacity(uint256 cap) public onlyOwner {
        maxCapacity = cap;
    }

    /// @dev Sets the address of the signer
    /// @param signerAddress_ The new signer's address
    function setSignerAddress(address signerAddress_) public onlyOwner {
        signerAddress = signerAddress_;
    }

    /// @dev Sets the minimum and maximum contribution amounts
    /// @param minAmount_ The new minimum amount of contribution
    /// @param maxAmount_ The new maximum amount of contribution
    function setMinMax(
        uint256 minAmount_,
        uint256 maxAmount_
    ) public onlyOwner {
        minAmount = minAmount_;
        maxAmount = maxAmount_;
    }

    /// @dev Sets the sale flag status
    /// @param saleFlag_ The new status of the sale flag
    function setSaleFlag(SaleFlag saleFlag_) public onlyOwner {
        saleFlag = saleFlag_;
    }
}
