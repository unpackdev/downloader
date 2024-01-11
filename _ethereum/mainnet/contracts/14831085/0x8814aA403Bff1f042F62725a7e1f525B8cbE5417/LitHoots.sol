//   _________
//  /_  ___   \
// /@ \/@  \   \
// \__/\___/   /
//  \_\/______/
//  /     /\\\\\
// |     |\\\\\\
//  \      \\\\\\\
//    \______/\\\\\
//     _||_||_
// LitHoots
// SPDX-License-Identifier: MIT
// @author LookingForOwls & Devberry.eth

pragma solidity 0.8.7;

import "./Ownable.sol";
import "./ERC721.sol";

    error MintingNotStarted();
    error TwigValueTooLow();
    error NotTokenOwner();
    error InvalidContract();

// Interfaces
interface IHoots {
    function balanceOf(address _user) external view returns (uint256);

    function ownerOf(uint256 _tokenId) external view returns (address);
}

interface ITwigs {
    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract LitHoots is ERC721, Ownable {
    // Project Variables
    string private baseURI;
    bool public started = false;
    address public constant DAO = 0x42A21bA79D2fe79BaE4D17A6576A15b79f5d36B0;
    uint256 public constant COST = 500 ether;

    ITwigs private twigs;
    address public hoots;
    address public alphas;

    constructor(address _hootAddress, address _alphaAddress, address _twigAddress) ERC721("LitHoots", "LHOOT") {
        hoots = _hootAddress;
        alphas = _alphaAddress;
        twigs = ITwigs(_twigAddress);
    }

    // Internal Functions
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // Check owner of Hoot
    function _checkOwner(address contractAddress, uint tokenId) internal view returns (address) {
        return IHoots(contractAddress).ownerOf(tokenId);
    }

    // Calculate correct ID for Hoots and Alphas
    function _getId(address contractAddress, uint tokenId) internal view returns (uint256) {
        if (address(contractAddress) == address(hoots)) {
            return tokenId;
        }
        else {
            return tokenId + 2500;
        }
    }

    // Mint functions
    function mint(address contractAddress, uint256[] calldata hootIds, uint256 payment) public {
        require (address(contractAddress) == hoots || address(contractAddress) == alphas, "Invalid Contract");
        if (!started) revert MintingNotStarted();
        if (payment < COST * hootIds.length) revert TwigValueTooLow();
        // verify ownership of all tokens.
        for (uint256 i = 0; i < hootIds.length; i++) {
            if (_checkOwner(contractAddress, hootIds[i]) != msg.sender) revert NotTokenOwner();
        }
        // Burn TWIGS
        twigs.transferFrom(msg.sender, 0x000000000000000000000000000000000000dEaD, payment);
        // Mint
        for (uint256 i = 0; i < hootIds.length; i++) {
            _mint(msg.sender, _getId(contractAddress, hootIds[i]));
        }
    }

    function enableMint(bool _state) external onlyOwner {
        started = _state;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setHootContract(address _hootAddress) external onlyOwner {
        hoots = _hootAddress;
    }

    function setAlphaContract(address _alphaAddress) external onlyOwner {
        alphas = _alphaAddress;
    }
	
    function setTwigContract(address _twigAddress) external onlyOwner {
        twigs = ITwigs(_twigAddress);
    }

    // Withdraw funds (Recover any ETH sent to contract)
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(DAO), balance);
    }
}
