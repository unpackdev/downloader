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
    
    mapping(uint256 => uint256) private _lastClaimDudes;
    mapping(uint256 => uint256) private _lastClaimSistas;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor (string memory name_, string memory symbol_, address dudesAddress, address sistasAddress, uint256 emissionStartTimestamp, address mintto) ERC20(name_, symbol_) {
        _name = name_;
        _symbol = symbol_;

        _dudesAddress = dudesAddress;
        _sistasAddress = sistasAddress;

        emissionStart = emissionStartTimestamp;
        emissionEnd = emissionStartTimestamp + (86400 * 365);

        _mint(mintto, 300000000000000000000000); 

        _mint(0x5B74047Ebf61fF768DA06ed6BDbE0d7Ff3430B79, 2027658888888888888888); 
        _mint(0xE1cAFC2bE75769b99aB0263e8C9437a25E2e7B92, 2025478972222222222222); 
        _mint(0x0108a5E3982148B29450a3F17B247C15B9523889, 1536865208333333333331); 
        _mint(0x550c0D109E2c4684b15264CA562d9B7AB1C6727F, 1515719583333333333333); 
        _mint(0xEFcfc90CAE34aF243Cc3Bc5f4271B5E762cd6512, 1509118333333333333332); 
        _mint(0x9e199d8A3a39c9892b1c3ae348A382662dCBaA12, 514671097222222222222); 
        _mint(0x6e37a0c2617C097E07D43fbC87bfc11a8Fd04698, 512893125000000000000); 
        _mint(0x5Da487Ea7278E25288fd4f0f9243e3Fa61bc7443, 504030677777777777777); 
        _mint(0x4bff03171268f4C7dEd7C7AF430F0e8792198B64, 503934519444444444444); 

        _lastClaimSistas[168] = 1630440568;
        _lastClaimSistas[170] = 1630440568;
        _lastClaimSistas[171] = 1630440568;
        _lastClaimSistas[238] = 1630472254;
        _lastClaimSistas[239] = 1630472254;
        _lastClaimSistas[240] = 1630472254;
        _lastClaimSistas[181] = 1630481319;
        _lastClaimSistas[182] = 1630481319;
        _lastClaimSistas[183] = 1630496372;
        _lastClaimSistas[213] = 1630496372;
        _lastClaimSistas[214] = 1630496372;
        _lastClaimSistas[215] = 1630496372;
        _lastClaimSistas[56] = 1630573753;
        _lastClaimSistas[61] = 1630573753;
        _lastClaimSistas[63] = 1630573753;
        _lastClaimSistas[51] = 1630582461;

        _lastClaimDudes[319] = 1630444278;
        _lastClaimDudes[881] = 1630448623;
        _lastClaimDudes[257] = 1630481115;
        _lastClaimDudes[602] = 1630481115;
        _lastClaimDudes[858] = 1630588858;



    }
    
    function lastClaimDudes(uint256 tokenIndex) public view returns (uint256) {
        require(IDudeSista(_dudesAddress).ownerOf(tokenIndex) != address(0), "Owner cannot be 0 address");
        require(tokenIndex < IDudeSista(_dudesAddress).totalSupply(), "NFT at index has not been minted yet");

        uint256 lastClaimed = uint256(_lastClaimDudes[tokenIndex]) != 0 ? uint256(_lastClaimDudes[tokenIndex]) : emissionStart;
        return lastClaimed;
    }

    function lastClaimSistas(uint256 tokenIndex) public view returns (uint256) {
        require(IDudeSista(_dudesAddress).ownerOf(tokenIndex) != address(0), "Owner cannot be 0 address");
        require(tokenIndex < IDudeSista(_dudesAddress).totalSupply(), "NFT at index has not been minted yet");

        uint256 lastClaimed = uint256(_lastClaimSistas[tokenIndex]) != 0 ? uint256(_lastClaimSistas[tokenIndex]) : emissionStart;
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

        uint256 lastClaimed = _address == _dudesAddress ? lastClaimDudes(tokenIndex) : lastClaimSistas(tokenIndex);

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
                if(_address == _dudesAddress) {
                    _lastClaimDudes[tokenIndex] = block.timestamp;
                } else {
                    _lastClaimSistas[tokenIndex] = block.timestamp;
                }
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