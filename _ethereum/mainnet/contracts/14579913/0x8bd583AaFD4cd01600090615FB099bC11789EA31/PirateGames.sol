// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./Pausable.sol";
import "./IPirateGames.sol";
import "./IPytheas.sol";
import "./IOrbitalBlockade.sol";
import "./ITPirates.sol";
import "./IRAW.sol";
import "./IPirates.sol";
import "./IColonist.sol";
import "./IImperialGuild.sol";
import "./IRandomizer.sol";

contract PirateGames is IPirateGames, Pausable {
    uint8[][6] public rarities;
    uint8[][6] public aliases;

    uint256 public OnosiaLiquorId;

    uint256 private maxRawEonCost;

    uint256 public imperialFee;

    // address => can call
    mapping(address => bool) private admins;

    address public auth;

    // reference to Pytheas for checking that a colonist has mined enough
    //rEON to make an attempt as well as pay from this amount, either the  current mint cost on
    //a successful pirate mint, or pirate tax on a failed attempt.
    IPytheas public pytheas;
    //reference to the OrbitalBlockade, where pirates are staked out, awaiting weak colonist miners.
    IOrbitalBlockade public orbital;
    // reference to raw Eon for attempts
    IRAW public raw;
    // reference to pirate collection
    IPirates public pirateNFT;
    // reference to the colonist NFT collection
    IColonist public colonistNFT;
    // reference to the galactic imperialGuild collection
    IImperialGuild public imperialGuild;
    //randy the randomizer
    IRandomizer private randomizer;

    //ratio chance

    constructor() {
        _pause();
        auth = msg.sender;
        admins[msg.sender] = true;

        //RatioChance 90
        rarities[0] = [27, 230];
        aliases[0] = [1, 0];
        //RatioChance 80
        rarities[1] = [51, 204];
        aliases[1] = [1, 0];
        //RatioChance 60
        rarities[2] = [90, 175];
        aliases[2] = [1, 0];
        //RatioChance 40
        rarities[3] = [155, 132];
        aliases[3] = [1, 0];
        //RatioChance 10
        rarities[4] = [200, 60];
        aliases[4] = [1, 0];
        //RatioChance 0
        rarities[5] = [255];
        aliases[5] = [0];
    }

    modifier noCheaters() {
        uint256 size = 0;
        address acc = msg.sender;
        assembly {
            size := extcodesize(acc)
        }

        require(
            admins[msg.sender] || (msg.sender == tx.origin && size == 0),
            "you're trying to cheat!"
        );
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == auth);
        _;
    }

    /** CRITICAL TO SETUP */
    modifier requireContractsSet() {
        require(
            address(raw) != address(0) &&
                address(pirateNFT) != address(0) &&
                address(colonistNFT) != address(0) &&
                address(pytheas) != address(0) &&
                address(orbital) != address(0) &&
                address(imperialGuild) != address(0) &&
                address(randomizer) != address(0),
            "Contracts not set"
        );
        _;
    }

    function setContracts(
        address _rEON,
        address _pirateNFT,
        address _colonistNFT,
        address _pytheas,
        address _orbital,
        address _imperialGuild,
        address _randomizer
    ) external onlyOwner {
        raw = IRAW(_rEON);
        pirateNFT = IPirates(_pirateNFT);
        colonistNFT = IColonist(_colonistNFT);
        pytheas = IPytheas(_pytheas);
        orbital = IOrbitalBlockade(_orbital);
        imperialGuild = IImperialGuild(_imperialGuild);
        randomizer = IRandomizer(_randomizer);
    }

    function pirateAttempt(uint16 tokenId, bool stake) external noCheaters whenNotPaused {
        uint16 piratesMinted = pirateNFT.piratesMinted();
        uint256 totalCir = colonistNFT.totalCir();
        uint256 minted = colonistNFT.minted();
        uint256 seed = random(minted);
        uint256 maxTokens = colonistNFT.getMaxTokens();
        uint256 rawCost = rawMintCost(minted, maxTokens);
        uint256 mined = pytheas.getColonistMined(msg.sender, tokenId);
        require(
            mined >= rawCost,
            "You have not mined enough to attempt this action"
        );
        uint8 chanceTable = getRatioChance(piratesMinted, totalCir);
        uint8 yayNay = getPirateResults(seed, chanceTable);
        // if the attempt fails, pay pirate tax and claim remaining
        if (yayNay == 0) {
            pytheas.payUp(tokenId, mined, msg.sender);
        } else {
            pytheas.handleJoinPirates(msg.sender, tokenId);
            uint256 outStanding = mined - rawCost;
            raw.updateMintBurns(1, mined, rawCost);
            raw.mint(1, outStanding, msg.sender);
            piratesMinted++;
            uint16[] memory pirateId = new uint16[](1);
            pirateId[0] = piratesMinted;
            address recipient = selectRecipient(seed);
            if (
                recipient != msg.sender &&
                imperialGuild.getBalance(msg.sender, OnosiaLiquorId) > 0
            ) {
                // If the mint is going to be stolen, there's a 50% chance
                //  a pirate will prefer a fine crafted EON liquor over it
                if (seed & 1 == 1) {
                    imperialGuild.safeTransferFrom(
                        msg.sender,
                        recipient,
                        OnosiaLiquorId,
                        1,
                        ""
                    );
                    recipient = msg.sender;
                }
            }
            if (!stake || recipient != msg.sender) {
                pirateNFT._mintPirate(recipient, seed);
            } else {
                pirateNFT._mintPirate(address(orbital), seed);
                
            }
            pirateNFT.updateOriginAccess(pirateId);
            if (stake) {
                orbital.addPiratesToCrew(msg.sender, pirateId);
            }
        }
    }
    

    /**
     * @param tokenId the ID to check the cost of to mint
     * @return the cost of the given token ID
     */
    function rawMintCost(uint256 tokenId, uint256 maxTokens)
        public
        view
        returns (uint256)
    {
        if (tokenId <= (maxTokens * 8) / 24) return 4000; //10k-20k
        if (tokenId <= (maxTokens * 12) / 24) return 16000; //20k-30k
        if (tokenId <= (maxTokens * 16) / 24) return 48000; //30k-40k
        if (tokenId <= (maxTokens * 20) / 24) return 122500; //40k-50k
        if (tokenId <= (maxTokens * 22) / 24) return 250000; //50k-55k
        return maxRawEonCost;
    }

    function getRatioChance(uint256 pirates, uint256 circulation)
        public
        pure
        returns (uint8)
    {
        uint256 ratio = (pirates * 10000) / circulation;

        if (ratio <= 100) {
            return 0;
        } else if (ratio <= 300 && ratio >= 100) {
            return 1;
        } else if (ratio <= 500 && ratio >= 300) {
            return 2;
        } else if (ratio <= 800 && ratio >= 500) {
            return 3;
        } else if (ratio <= 999 && ratio >= 800) {
            return 4;
        } else {
            return 5;
        }
    }

    /**
  Determines if an attempt to join the pirates is successful or not 
  granting a higher chance of success when the pirate to colonist ratio is
  low, as the ratio gets closer to 10% the harder a chance at joining the pirates
  becomes until ultimately they will not accept anyone else if the ratio is += 10%
 */

    function getPirateResults(uint256 seed, uint8 chanceTable)
        internal
        view
        returns (uint8)
    {
        seed >>= 16;
        uint8 yayNay = getResult(uint16(seed & 0xFFFF), chanceTable);
        return yayNay;
    }

    function getResult(uint256 seed, uint8 chanceTable)
        internal
        view
        returns (uint8)
    {
        uint8 result = uint8(seed) % uint8(rarities[chanceTable].length);
        // If the selected chance talbles rareity is selected (biased coin) return that
        if (seed >> 8 < rarities[chanceTable][result]) return result;
        // else return the aliases
        return aliases[chanceTable][result];
    }

    /** INTERNAL */

    /**
     * the first 10k colonist mints go to the minter
     * the remaining 80% have a 10% chance to be given to a random staked pirate
     * @param seed a random value to select a recipient from
     * @return the address of the recipient (either the minter or the pirate thief's owner)
     */
    function selectRecipient(uint256 seed) internal view returns (address) {
        if (((seed >> 245) % 10) != 0) return msg.sender; // top 10 bits
        address thief = orbital.randomPirateOwner(seed >> 144); // 144 bits reserved for trait selection
        if (thief == address(0x0)) return msg.sender;
        return thief;
    }

    /**
     * enables owner to pause / unpause contract
     */
    function setPaused(bool _paused) external requireContractsSet onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }


    function setOnosiaLiquorId(uint256 typeId) external onlyOwner {
        OnosiaLiquorId = typeId;
    }

    /**
     * enables an address to mint / burn
     * @param addr the address to enable
     */
    function addAdmin(address addr) external onlyOwner {
        admins[addr] = true;
    }

    /**
     * disables an address from minting / burning
     * @param addr the address to disable
     */
    function removeAdmin(address addr) external onlyOwner {
        admins[addr] = false;
    }

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
}
