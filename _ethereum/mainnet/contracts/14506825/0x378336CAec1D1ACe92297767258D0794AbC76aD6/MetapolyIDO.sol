// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./Ownable.sol";
import "./ECDSA.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ERC721A.sol";
import "./BaseRelayRecipient.sol";

contract MetapolyIDO is Ownable, ERC721A, BaseRelayRecipient {
    using SafeERC20 for IERC20;

    IERC20 public immutable USDT;
    IERC20 public immutable USDC;

    uint public mintPriceInETH; // 18 decimals
    uint public mintPriceInUSD; // 6 decimals
    string constant baseURI = "https://genesis.metapoly.org/";
    uint constant maxSupply = 300;
    address signer;

    uint public phase1Start;
    uint public phase1Limit;
    uint public phase2Start;
    uint public mintEnd;

    constructor(
        IERC20 _USDT, IERC20 _USDC,
        uint _mintPriceInETH, uint _mintPriceInUSD,
        uint _phase1Start, uint _phase2Start, uint _mintEnd,
        address _signer, address _biconomy
    ) ERC721A("Metapoly IDO", "MetapolyIDO") {
        USDT = _USDT;
        USDC = _USDC;
        mintPriceInETH = _mintPriceInETH;
        mintPriceInUSD = _mintPriceInUSD;
        phase1Start = _phase1Start;
        phase1Limit = 1;
        phase2Start = _phase2Start;
        mintEnd = _mintEnd;
        signer = _signer;
        trustedForwarder = _biconomy;
    }

    function mintWithETH(bytes calldata signature, uint amount) external payable {
        require(msg.value == mintPriceInETH * amount, "Invalid price in ETH");
        _mint(signature, amount);
    }

    function mintWithUSD(bytes calldata signature, IERC20 token, uint amount) external {
        require(token == USDT || token == USDC, "Invalid token");
        token.safeTransferFrom(_msgSender(), address(this), mintPriceInUSD * amount);
        _mint(signature, amount);
    }

    function _mint(bytes calldata signature, uint amount) private {
        require(totalSupply() < maxSupply, "Max supply");
        require(block.timestamp > phase1Start && block.timestamp < mintEnd, "Not in period");

        // Phase 1, whitelisted only, 1 mint per wallet
        if (block.timestamp < phase2Start) {
            require(balanceOf(_msgSender()) < phase1Limit && amount == phase1Limit, "Mint limit reached");
            bytes32 message = keccak256(abi.encodePacked(_msgSender()));
            bytes32 messageHash = ECDSA.toEthSignedMessageHash(message);
            address recoveredAddr = ECDSA.recover(messageHash, signature);
            require(recoveredAddr == signer, "Invalid signature");
        }
        // Phase 2, no whitelisted needed, unlimited mint per wallet

        _safeMint(_msgSender(), amount);
    }

    function withdrawToTreasury(address treasury) external onlyOwner {
        // Withdraw ETH
        uint ETHBal = address(this).balance;
        if (ETHBal > 0) {
            (bool success,) = treasury.call{value: ETHBal}("");
            require(success, "Withdraw failed");
        }
        // Withdraw ERC20
        uint USDTBal = USDT.balanceOf(address(this));
        if (USDTBal > 0) USDT.safeTransfer(treasury, USDTBal);
        uint USDCBal = USDC.balanceOf(address(this));
        if (USDCBal > 0) USDC.safeTransfer(treasury, USDCBal);
    }

    function _transfer(address from, address to, uint _tokenId) internal override {
        require(isTransferable(), "Cannot transfer");
        super._transfer(from, to, _tokenId);
    }

    function setMintPrice(uint _mintPriceInETH, uint _mintPriceInUSD) external onlyOwner {
        mintPriceInETH = _mintPriceInETH;
        mintPriceInUSD = _mintPriceInUSD;
    }

    function setMintTimestamp(uint _phase1Start, uint _phase2Start, uint _mintEnd) external onlyOwner {
        if (phase1Start != _phase1Start) phase1Start = _phase1Start;
        if (phase2Start != _phase2Start) phase2Start = _phase2Start;
        if (mintEnd != _mintEnd) mintEnd = _mintEnd;
    }

    function setMintLimit(uint _phase1Limit) external onlyOwner {
        phase1Limit = _phase1Limit;
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function setBiconomy(address _trustedForwarder) external onlyOwner {
        trustedForwarder = _trustedForwarder;
    }

    /// @notice Only can transfer after phase 1 to check 1 mint per wallet within phase 1
    function isTransferable() public view returns (bool) {
        if (block.timestamp > phase2Start) return true;
        return false;
    }

    function _baseURI() internal pure override returns (string memory) {
        return baseURI;
    }

    function getOwnerOfAllNFTs() external view returns (address[] memory owners) {
        uint _totalSupply = totalSupply();
        owners = new address[](_totalSupply);
        for (uint i; i < _totalSupply; i ++) {
            owners[i] = ownerOf(i);
        }
    }

    function _msgSender() internal override(Context, BaseRelayRecipient) view returns (address) {
        return BaseRelayRecipient._msgSender();
    }

    function versionRecipient() external pure override returns (string memory) {
        return "1";
    }
}
