// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MerkleProof.sol";
import "./OwnableUpgradeable.sol";
import "./IERC721.sol";
import "./IERC1155.sol";

interface IOmegaKongsClub is IERC721 {
    function mint(address recipient, uint256 amount) external;
    function totalSupply() external view returns (uint256);
}

interface IBlueBananaSerum is IERC1155 {    
    function burnMultiple(uint256 serumType, uint256 amount, address serumOwner) external;
}

interface IAKCCore {
    function userToAKC(address user, uint256 spec) external view returns (uint256);
    function getTribeSpecAmount() external view returns(uint256);
}

interface IAKCStake {
    function userToStakeData(address user, uint256 spec) external view returns (uint256);
    function getStakeAmountFromStakeData(uint256 stakeData) external pure returns (uint256);
}

contract OmegaKongsClubMint is OwnableUpgradeable {
    IOmegaKongsClub public omegaKongsClub;
    IBlueBananaSerum public blueBananaSerum;
    IERC721 public akc;
    IAKCCore public core;
    IAKCStake public stake;

    uint256 public MAX_SUPPLY;
    uint256 public MINT_MAX_SUPPLY;

    uint256 public STAKE_MINT_LIMIT;
    uint256 public HOLDERS_MINT_LIMIT;
    uint256 public PUBLIC_MINT_LIMIT;

    uint256 public STAKE_MINT_START;
    uint256 public HOLDERS_MINT_START;
    uint256 public PUBLIC_MINT_START;
    uint256 public SERUM_MINT_START;

    uint256 public STAKE_MINT_END;
    uint256 public HOLDERS_MINT_END;
    uint256 public PUBLIC_MINT_END;
    uint256 public SERUM_MINT_END;

    mapping(address => uint256) public STAKE_MINTED;
    mapping(address => uint256) public HOLDERS_MINTED;
    mapping(address => uint256) public PUBLIC_MINTED;
   
    uint256 public mintPrice;
    bytes32 public stakersMerkleRoot;
     mapping(uint256 => bool) public KongToSerumStatus; // true = drank, false = not drank

    receive() external payable {}

    constructor(
        address okc,
        address bbs,
        address _akc,
        address _akcCore,
        address _akcStake
    ) {}

    function initialize(        
        address okc,
        address bbs,
        address _akc,
        address _akcCore,
        address _akcStake
    ) public initializer {
        __Ownable_init();

        omegaKongsClub = IOmegaKongsClub(okc);
        blueBananaSerum = IBlueBananaSerum(bbs);
        akc = IERC721(_akc);
        core = IAKCCore(_akcCore);
        stake = IAKCStake(_akcStake);

        MAX_SUPPLY = 10000;
        MINT_MAX_SUPPLY = 3800;

        STAKE_MINT_LIMIT = 10;
        HOLDERS_MINT_LIMIT = 4;
        PUBLIC_MINT_LIMIT = 2;

        STAKE_MINT_START = 1654452000; // 20:00 PM CEST June 5th
        HOLDERS_MINT_START = 1654459200; // 22:00 PM CEST June 5th
        PUBLIC_MINT_START = 1654538400; // 20:00 PM CEST June 6th
        SERUM_MINT_START = 1654624800; // 20:00 PM CEST June 7th

        STAKE_MINT_END = HOLDERS_MINT_START; // 22:00 PM CEST June 5th
        HOLDERS_MINT_END = HOLDERS_MINT_START + 4 * 3600; // 02:00 AM CEST June 6th
        PUBLIC_MINT_END = SERUM_MINT_START; // 20:00 PM CEST June 7th
        SERUM_MINT_END = SERUM_MINT_START + 31 days; // 20:00 PM CEST July 7th

        mintPrice = 0.25 ether;
    }

    function stakersMint(uint256 amount, bytes32[] calldata proof) external payable {
        require(block.timestamp >= STAKE_MINT_START, "ERR: STAKE MINT NOT STARTED");
        require(block.timestamp < STAKE_MINT_END, "ERR: STAKE MINT ENDED");
        
        require(STAKE_MINTED[msg.sender] + amount <= STAKE_MINT_LIMIT, "ERR: STAKE MINT LIMIT EXCEEDED");
        require(omegaKongsClub.totalSupply() + amount <= MINT_MAX_SUPPLY, "ERR: MINT LIMIT EXCEEDED");
        require(msg.value >= amount * mintPrice, "ERR: NOT ENOUGH ETH SENT");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, stakersMerkleRoot, leaf), "ERR: MERKLE PROOF INVALID");

        omegaKongsClub.mint(msg.sender, amount);
        STAKE_MINTED[msg.sender] += amount;
    }

    function _isUserHolder(address user, uint256 coreSpec, uint256 stakeSpec) internal view returns (bool) {
        if (akc.balanceOf(user) > 0)
            return true;
        
        uint256 coreKong = core.userToAKC(user, coreSpec);
        if (coreKong > 0)
            return true;
        
        uint256 stakeData = stake.userToStakeData(user, stakeSpec);
        uint256 stakeAmount = stake.getStakeAmountFromStakeData(stakeData);
        if (stakeAmount > 0)
            return true;
        
        return false;
    }

    function holdersMint(uint256 amount, uint256 coreSpec, uint256 stakeSpec) external payable {
        require(block.timestamp >= HOLDERS_MINT_START, "ERR: HOLDERS MINT NOT STARTED");
        require(block.timestamp < HOLDERS_MINT_END, "ERR: HOLDERS MINT ENDED");
        
        require(HOLDERS_MINTED[msg.sender] + amount <= HOLDERS_MINT_LIMIT, "ERR: HOLDERS MINT LIMIT EXCEEDED");
        require(omegaKongsClub.totalSupply() + amount <= MINT_MAX_SUPPLY, "ERR: MINT LIMIT EXCEEDED");
        require(msg.value >= amount * mintPrice, "ERR: NOT ENOUGH ETH SENT");

        require(_isUserHolder(msg.sender, coreSpec, stakeSpec), "ERR: USER NOT HOLDER");

        omegaKongsClub.mint(msg.sender, amount);
        HOLDERS_MINTED[msg.sender] += amount;
    }

    function publicMint(uint256 amount) external payable {
        require(block.timestamp >= PUBLIC_MINT_START, "ERR: PUBLIC MINT NOT STARTED");
        require(block.timestamp < PUBLIC_MINT_END, "ERR: PUBLIC MINT ENDED");
        
        require(PUBLIC_MINTED[msg.sender] + amount <= PUBLIC_MINT_LIMIT, "ERR: PUBLIC MINT LIMIT EXCEEDED");
        require(omegaKongsClub.totalSupply() + amount <= MINT_MAX_SUPPLY, "ERR: MINT LIMIT EXCEEDED");
        require(msg.value >= amount * mintPrice, "ERR: NOT ENOUGH ETH SENT");        

        omegaKongsClub.mint(msg.sender, amount);
        PUBLIC_MINTED[msg.sender] += amount;
    }

    function sendEthToRecipient(address _to) external onlyOwner {
        require(_to != address(0), "CANNOT WITHDRAW TO ZERO ADDRESS");
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "NO ETHER TO WITHDRAW");
        payable(_to).transfer(contractBalance);
    }

    function setMaxSupply(uint256 _max, uint256 _mintMax) external onlyOwner {
        MAX_SUPPLY = _max;
        MINT_MAX_SUPPLY = _mintMax;
    }

    function setMintLimits(uint256 _stake, uint256 _holders, uint256 _public) external onlyOwner {
        STAKE_MINT_LIMIT = _stake;
        HOLDERS_MINT_LIMIT = _holders;
        PUBLIC_MINT_LIMIT = _public;
    }

    function startTimes_setStake(uint256 _t) external onlyOwner {
        STAKE_MINT_START = _t;
    }

    function startTimes_setHolders(uint256 _t) external onlyOwner {
        HOLDERS_MINT_START = _t;
    }

    function startTimes_setPublic(uint256 _t) external onlyOwner {
        PUBLIC_MINT_START = _t;
    }

    function startTimes_setSerum(uint256 _t) external onlyOwner {
        SERUM_MINT_START = _t;
    }

    function endTimes_setStake(uint256 _t) external onlyOwner {
        STAKE_MINT_END = _t;
    }

    function endTimes_setHolders(uint256 _t) external onlyOwner {
        HOLDERS_MINT_END = _t;
    }

    function endTimes_setPublic(uint256 _t) external onlyOwner {
        PUBLIC_MINT_END = _t;
    }

    function endTimes_setSerum(uint256 _t) external onlyOwner {
        SERUM_MINT_END = _t;
    }

    function setStakersMerkleRoot(bytes32 root) external onlyOwner {
        stakersMerkleRoot = root;
    }

    function setMintPrice(uint256 newPrice) external onlyOwner {
        mintPrice = newPrice;
    }

    function setContracts(address _okc, address _bbs, address _akc, address _core, address _stake) external onlyOwner {
        omegaKongsClub = IOmegaKongsClub(_okc);
        blueBananaSerum = IBlueBananaSerum(_bbs);
        akc = IERC721(_akc);
        core = IAKCCore(_core);
        stake = IAKCStake(_stake);
    }

    // Returns spec + 1 as we're starting from 0 and 0 denotes "not found"
    function getFirstTribeWithStakedKongFromCore(address user) external view returns(uint256) {
        uint256 tribeSpecsAmount = core.getTribeSpecAmount();
        bool found = false;
        uint256 targetSpec;

        for (uint i = 0; i < tribeSpecsAmount; i++) {
            if (found)
                break;

            uint data = core.userToAKC(user, i);
            if (data > 0) {
                found = true;
                targetSpec = i + 1;
            }
        }

        if (!found) {
            uint data = core.userToAKC(user, 257);
            if (data > 0) {                
                targetSpec = 258;
            }
        }

        return targetSpec;
    }

    // return spec + 1 as we're starting from 0 and 0 denotes "not found"
    function getFirstTribeWithStakedKongFromStake(address user) external view returns(uint256) {
        uint256 tribeSpecsAmount = core.getTribeSpecAmount();
        bool found = false;
        uint256 targetSpec;

        for (uint i = 0; i < tribeSpecsAmount; i++) {
            if (found)
                break;

            uint256 stakeData = stake.userToStakeData(user, i);
            uint256 stakeAmount = stake.getStakeAmountFromStakeData(stakeData);
            if (stakeAmount > 0) {
                found = true;
                targetSpec = i + 1;
            }
        }

        if (!found) {
            uint256 stakeData = stake.userToStakeData(user, 257);
            uint256 stakeAmount = stake.getStakeAmountFromStakeData(stakeData);
            if (stakeAmount > 0) {
                found = true;
                targetSpec = 258;
            }
        }

        return targetSpec;
    }
}