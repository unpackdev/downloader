// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "ReentrancyGuard.sol";
import "ECDSA.sol";
import "SafeERC20.sol";

import "BCANFT1155Base.sol";

contract TakeOffBase is BCANFT1155Base, ReentrancyGuard, Ownable {
    using Strings for uint256;
    using SafeERC20 for IERC20;

    address public validator;
    address public cfo = address(0xba6c9562A0a7d482267E07999CF6968064a8e7de);

    uint256 public constant whitelistMintStartTime = 1654084800; //2022-06-01 20:00+GMT8
    uint256 public constant publicSaleMintStartTime = 1654948800; //2022-06-11 20:00+GMT8

    uint256 public constant whitelistPrice = 8e16; //0.08 ETH
    uint256 public constant publicSalePrice = 2e17; //0.2 ETH

    uint256 public constant reserveAmount = 30;
    uint256 public reserveEndTime = 1655208000; //2022-06-14 20:00+GMT8

    //    userAddress _isWhitelistMinted
    mapping(address => bool) _isWhitelistMinted;
    //    userAddress _isPublicSaleMinted
    mapping(address => bool) _isPublicSaleMinted;

    /**
        @dev
        @param _maxSupply
    */
    constructor(string memory name_, string memory symbol_, uint256 maxSupply_, string memory uri,
        RoyaltyInfo memory royaltyInfo,
        address validator_)
    BCANFT1155Base(name_, symbol_, maxSupply_, uri, royaltyInfo) {
        validator = validator_;
    }

    function publicMintTo(address to) public payable nonReentrant {
        require(block.timestamp >= publicSaleMintStartTime, "Public Sale Mint is Not start!");
        require(!_isPublicSaleMinted[to], "Address had already minted in public sale!");
        _isPublicSaleMinted[to] = true;

        uint256 amount = 1;
        uint256 paymentAmount = publicSalePrice * amount;
        require(msg.value == paymentAmount, "Incorrect payment value");
        payable(cfo).transfer(paymentAmount);

        require(totalSupply() + amount <= maxSupply - getReserveAmount(), "Mint count exceeded max allow!");
        mintTo(to);
    }

    function getReserveAmount() public view returns (uint256) {
        if (block.timestamp >= reserveEndTime) {
            return 0;
        }
        return reserveAmount;
    }

    function updateReserveEndTime(uint256 newReserveEndTime) public onlyOwner {
        reserveEndTime = newReserveEndTime;
    }

    function whiteListMintTo(address to, uint256 amount, bytes memory validatorSig) public payable nonReentrant {
        require(block.timestamp >= whitelistMintStartTime, "WL Mint is Not start!");
        require(0 < amount, "mint amount must > 0!");
        require(amount <= 2, "mint count exceed max allow 2");
        checkWhitelistMintValidator(to, validatorSig);
        require(!_isWhitelistMinted[to], "Address had already minted in whitelist!");
        _isWhitelistMinted[to] = true;
        uint256 paymentAmount = whitelistPrice * amount;
        require(msg.value == paymentAmount, "Incorrect payment value");
        payable(cfo).transfer(paymentAmount);
        require(totalSupply() + amount <= maxSupply - getReserveAmount(), "Mint count exceeded max allow!");

        mintBatch(to, amount);
    }

    /**
       @dev airdropMintTo
    */
    function airdropMintTo(address[] memory tos, uint256[] memory amounts) public onlyOwner {
        require(tos.length == amounts.length, "tos and amounts length mismatch");

        for (uint256 i = 0; i < tos.length; i++) {
            mintBatch(tos[i], amounts[i]);
        }
    }

    function isWhitelistMinted(address userAddress) public view returns (bool isMinted){
        return _isWhitelistMinted[userAddress];
    }

    function isPublicSaleMinted(address userAddress) public view returns (bool isMinted){
        return _isPublicSaleMinted[userAddress];
    }

    function checkWhitelistMintValidator(address mintToAddress, bytes memory validatorSig) public view {
        bytes32 validatorHash = keccak256(abi.encodePacked(mintToAddress));
        checkSign(validatorSig, ECDSA.toEthSignedMessageHash(validatorHash), validator, "invalid validator sign!");
    }

    function setValidator(address newValidator) external onlyOwner {
        require(newValidator != address(0) && validator != newValidator, "invalid newValidator address!");
        validator = newValidator;
    }

    function setCFOAddress(address newCFO) public onlyOwner {
        require(newCFO != address(0) && cfo != newCFO, "invalid newCFO address!");
        cfo = newCFO;
    }

    function checkSign(bytes memory sign, bytes32 hashCode, address signer, string memory words) public pure {
        require(ECDSA.recover(hashCode, sign) == signer, words);
    }

    /**
        In case money get Stuck in the contract
    */
    function withdraw(address payable to, uint256 amount) external onlyOwner {
        to.transfer(amount);
    }

    function withdrawERC20(address erc20Address, address to, uint256 amount) external onlyOwner {
        IERC20(erc20Address).safeTransfer(to, amount);
    }

    function setURI(string memory newuri) public virtual onlyOwner {
        _setURI(newuri);
    }
}

