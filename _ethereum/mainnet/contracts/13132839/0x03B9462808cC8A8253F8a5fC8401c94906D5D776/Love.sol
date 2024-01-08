// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./SafeMath.sol";
import "./ERC20.sol";
import "./Ownable.sol";
import "./Context.sol";
import "./ERC721Enumerable.sol";

contract LoveToken is Context, ERC20, Ownable {
    using SafeMath for uint256;

    uint256 public constant INITIAL_REWARD = 500 * (10 ** 18);

    address private _dudesAddress;
    address private _sistasAddress;
    address private _allowedBurner;
    
    uint256 public emissionStart;
    uint256 public emissionEnd; 
    uint256 public emissionPerDay = 6 * (10 ** 18);

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;
    
    mapping(uint256 => uint256) private _lastClaim;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor (string memory name_, string memory symbol_, address dudesAddress, address sistasAddress, uint256 emissionStartTimestamp) ERC20(name_, symbol_) {
        _name = name_;
        _symbol = symbol_;

        _dudesAddress = dudesAddress;
        _sistasAddress = sistasAddress;

        emissionStart = emissionStartTimestamp;
        emissionEnd = emissionStartTimestamp + (86400 * 365);
    }
    
    function lastClaim(uint256 tokenIndex) public view returns (uint256) {
        require(IDudeSista(_dudesAddress).ownerOf(tokenIndex) != address(0), "Owner cannot be 0 address");
        require(tokenIndex < IDudeSista(_dudesAddress).totalSupply(), "NFT at index has not been minted yet");

        uint256 lastClaimed = uint256(_lastClaim[tokenIndex]) != 0 ? uint256(_lastClaim[tokenIndex]) : emissionStart;
        return lastClaimed;
    }

    function setAllowedBurner(address allowedBurner) external onlyOwner {
        _allowedBurner = allowedBurner;
    }
    
    function accumulatedForDude(uint256 tokenIndex) public view returns (uint256) {
        return accumulated(_dudesAddress, tokenIndex);
    }

    function accumulatedForSista(uint256 tokenIndex) public view returns (uint256) {
        return accumulated(_sistasAddress, tokenIndex);
    }    

    function accumulated(address _address, uint256 tokenIndex) public view returns (uint256) {
        require(block.timestamp > emissionStart, "Emission has not started yet");
        require(IDudeSista(_address).ownerOf(tokenIndex) != address(0), "Owner cannot be 0 address");
        require(tokenIndex < IDudeSista(_address).totalSupply(), "NFT at index has not been minted yet");

        uint256 lastClaimed = lastClaim(tokenIndex);

        if (lastClaimed >= emissionEnd) return 0;

        uint256 accumulationPeriod = block.timestamp < emissionEnd ? block.timestamp : emissionEnd; // Getting the min value of both

        (uint256 a, uint256 b, uint256 c, uint256 wealth, uint256 e, uint256 f) = IDudeSista(_address).getSkills(tokenIndex);
        uint256 dailyEmissionWithBoost = emissionPerDay.add(wealth * 2 * (10 ** 16));
        uint256 totalAccumulated = accumulationPeriod.sub(lastClaimed).mul(dailyEmissionWithBoost).div(86400);

        if (lastClaimed == emissionStart) {
            totalAccumulated = totalAccumulated.add(INITIAL_REWARD);
        }

        return totalAccumulated;
    }
    
    function claimForDudes(uint256[] memory tokenIndices) public returns (uint256) {
        return claim(_dudesAddress, tokenIndices);
    }

    function claimForSistas(uint256[] memory tokenIndices) public returns (uint256) {
        return claim(_sistasAddress, tokenIndices);
    }

    function claim(address _address, uint256[] memory tokenIndices) internal returns (uint256) {
        require(block.timestamp > emissionStart, "Emission has not started yet");

        uint256 totalClaimQty = 0;
        for (uint i = 0; i < tokenIndices.length; i++) {
            // Sanity check for non-minted index
            require(tokenIndices[i] < IDudeSista(_address).totalSupply(), "NFT at index has not been minted yet");

            for (uint j = i + 1; j < tokenIndices.length; j++) {
                require(tokenIndices[i] != tokenIndices[j], "Duplicate token index");
            }

            uint tokenIndex = tokenIndices[i];
            require(IDudeSista(_address).ownerOf(tokenIndex) == msg.sender, "Sender is not the owner");

            uint256 claimQty = accumulated(_address, tokenIndex);
            if (claimQty != 0) {
                totalClaimQty = totalClaimQty.add(claimQty);
                _lastClaim[tokenIndex] = block.timestamp;
            }
        }

        require(totalClaimQty != 0, "No accumulated love");
        _mint(msg.sender, totalClaimQty); 
        return totalClaimQty;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        if (msg.sender != _allowedBurner) {
            _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        }
        return true;
    }

    function burn(uint256 burnQuantity) public returns (bool) {
        _burn(msg.sender, burnQuantity);
        return true;
    }
}

interface IDudeSista is IERC721Enumerable {
    function getSkills(uint256 tokenId) external view returns (uint, uint, uint, uint, uint, uint);
}