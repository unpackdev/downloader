// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.1;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC721Enumerable.sol";
import "./IWildAbduction.sol";
import "./IBank.sol";
import "./ITraits.sol";
import "./ILAND.sol";
import "./IRandomizer.sol";

contract WAGGame is Ownable, Pausable, ERC721Enumerable {

    bool private _reentrant = false;

    modifier nonReentrant() {
        require(!_reentrant, "No reentrancy");
        _reentrant = true;
        _;
        _reentrant = false;
    }

    struct Whitelist {
    bool isWhitelisted;
    uint16 numMinted;
    bool freeMint;
    }

    bool public hasPublicSaleStarted;
    uint256 public presalePrice = 0.025 ether;
    uint256 public publicPrice = 0.04 ether;
    uint256 maxLandCost = 70000 ether;
    uint256 maxTokens = 40000;
    uint256 private startedTime;

    mapping (address => Whitelist) private _whitelistAddresses;
    mapping (address => bool) private _freeMintAddresses;

    ILAND public land;
    ITraits public traits;
    IWildAbduction wagNFT;
    IBank bank;

    constructor(ILAND _land, ITraits _traits, IWildAbduction _wagNFT) ERC721("WAG Game", 'WGAME') {
        land = _land;
        hasPublicSaleStarted = false;
        wagNFT = _wagNFT;
        _pause;
        traits = _traits;
        startedTime = block.timestamp;
    }

    modifier requireContractsSet() {
      require(address(land) != address(0) && address(traits) != address(0) 
        && address(wagNFT) != address(0) && address(bank) != address(0)
        , "Contracts not set");
      _;
    }

    function setBank(address _bank) external onlyOwner {
        bank = IBank(_bank);
    }
    

    /* EXTERNAL */

    /**
     * mint a token - 88.75% Cowboy, 10% Alien, 1.25% Mutant
     * The first 11.11% are free to claim, the remaining cost $LAND
     */

     function mint(uint256 amount, bool stake) external payable whenNotPaused nonReentrant requireContractsSet {
        require(tx.origin == _msgSender(), "Only EOA");
        uint16 minted = wagNFT.minted();
        uint256 paidTokens = wagNFT.getPaidTokens();
        require(amount + minted <= maxTokens);
        require(amount > 0 && amount <= 20, "Invalid mint amount");

        if (minted < paidTokens) {
            require(minted + amount <= paidTokens, "All gen 0's minted");
            if (hasPublicSaleStarted) {
                require(msg.value >= amount * publicPrice, "Invalid payment amount");
            } else {
                require(_whitelistAddresses[_msgSender()].isWhitelisted, "Not on whitelist");
                if (_whitelistAddresses[_msgSender()].freeMint == true) {
                    require(msg.value == (amount * presalePrice) - presalePrice);
                    _whitelistAddresses[_msgSender()].freeMint = false;
                } else {
                    require(msg.value == amount * presalePrice, "Invalid payment amount");
                }
                require(_whitelistAddresses[_msgSender()].numMinted + amount <= 20, "too many mints");
                _whitelistAddresses[_msgSender()].numMinted += uint16(amount);
            }
        } else {
            require(msg.value == 0);
        }

        uint256 totalLandCost = 0;
        uint16[] memory tokenIds = new uint16[](amount);
        uint256 seed = 0;

        for  (uint i = 0; i < amount; i++) {
            minted++;
            seed = random(minted);
            address recipient = _msgSender();

            if (minted <= paidTokens || ((seed >> 245) % 10) != 0) {
                recipient = _msgSender();
            } else {
                recipient = bank.randomAlienOwner(seed >> 144);
                if (recipient == address(0x0)) {
                    recipient = _msgSender();
                }
            }

            tokenIds[i] = minted;
            if (!stake || recipient != _msgSender()) {
                wagNFT.mint(recipient, seed);
            } else {
                wagNFT.mint(address(bank), seed);
            }
            totalLandCost += mintCost(minted, paidTokens);
        }

        if (totalLandCost > 0) {
            land.burn(_msgSender(), totalLandCost);
        }

        if (stake) {
            bank.addManyToBankAndPack(_msgSender(), tokenIds);
        }
    }

    function addToWhitelist(address[] calldata addressesToAdd, bool freeMint) external onlyOwner {
        for (uint256 i = 0; i < addressesToAdd.length; i++) {
            _whitelistAddresses[addressesToAdd[i]] = Whitelist(true, 0, freeMint);
        }
    }

    function setPublicSaleStart(bool started) external onlyOwner {
        hasPublicSaleStarted = started;
        if(hasPublicSaleStarted) {
            startedTime = block.timestamp;
        }
    } 

     /**
     * the first 4444 are paid in ETH
     * 4445 - 20,000 are 20000 $land
     * 20,001 - 30,000 are 40000 $land
     * 30,001 - 40,000 are 70000 $land
     * @param tokenId the ID to check the cost of to mint
   * @return the cost of the given token ID
   */
    function mintCost(uint256 tokenId, uint256 paidTokens) public view returns (uint256) {
        if (tokenId <= paidTokens) return 0;
        if (tokenId <= maxTokens * 1 / 2) return 20000 ether;
        if (tokenId <= maxTokens * 3 / 4) return 40000 ether;
        return 70000 ether;
    }

    /** INTERNAL */

  /**
   * the first 25% (ETH purchases) go to the minter
   * the remaining 80% have a 10% chance to be given to a random staked dragon
   * @param seed a random value to select a recipient from
   * @return the address of the recipient (either the minter or the Dragon thief's owner)
   */
    function selectRecipient(uint256 seed, uint256 minted, uint256 paidTokens) internal view returns (address) {
        if (minted <= paidTokens || ((seed >> 245) % 10) != 0) return _msgSender(); // top 10 bits haven't been used
        address thief = bank.randomAlienOwner(seed >> 144); // 144 bits reserved for trait selection
        if (thief == address(0x0)) return _msgSender();
        return thief;
    }

    /**
     * generates a pseudorandom number
     * @param seed a value ensure different outcomes for different sources in the same block
   * @return a pseudorandom value
   */
    function random(uint256 seed) internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        tx.origin,
                        blockhash(block.number - 1),
                        block.timestamp,
                        seed
                    )
                )
            );
    }

    
    /** ADMIN */
    /**
    * enables owner to pause / unpause contract
    */
    function setPaused(bool _paused) external requireContractsSet onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    function setmaxLandCost(uint256 _amount) external requireContractsSet onlyOwner {
        maxLandCost = _amount;
    } 

    /**
    * allows owner to withdraw funds from minting
    */
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

}