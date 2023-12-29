// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./IERC721EnumerableUpgradeable.sol";
import "./IERC1820RegistryUpgradeable.sol";

import "./GameEnums.sol";
import "./IAuthenticator.sol";
import "./TokenRetriever.sol";
import "./ICryptopiaEarlyAccessShipToken.sol";

/// @title Cryptopia EarlyAccessShip (EAS) Token Factory 
/// @dev Non-fungible token (ERC721) factory that mints CryptopiaEarlyAccessShip tokens
/// @author HFB - <frank@cryptopia.com>
contract CryptopiaEarlyAccessShipTokenFactory is Initializable, OwnableUpgradeable, TokenRetriever, IERC721ReceiverUpgradeable {

    /**
     *  Structs
     */
    struct MintData 
    {
        bytes32 rare;
        bytes32 legendary;
    }


    /**
     *  Storage
     */
    uint constant public MAX_SUPPLY = 10_000;
    uint constant public MINT_FEE = 0.125 ether;
    uint constant public REFERAL_FEE = 0.0125 ether;

    // Random
    uint constant public INVERSE_BASIS_POINT = 10_000; 
    uint constant public MIN_LEGENDARY_SCORE = 99_00; // 1%
    uint constant public MIN_RARE_SCORE = 85_00; // 14%

    // For burning legacy ships
    address constant private ERC1820_ADDRESS = 0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24;
    bytes32 constant private ERC777_RECIPIENT_INTERFACE = keccak256("ERC777TokensRecipient");

    // Beneficiary
    address payable public beneficiary;

    /// @dev ship => MintData
    mapping (bytes32 => MintData) public mintData;

    /// @dev tokenId => timestamp
    mapping (uint => uint128) public legacyMintedAt;

    /// @dev tokenId => special
    mapping (uint => bytes32) public legacySpecial; 

    /// @dev referrer => address
    mapping (bytes32 => address) public referrers;

    // State
    address public shipToken;
    address public legacyShipToken;

    uint private _upgradableSupply;
    uint private _currentTokenId; 
    bytes32 private _currentRandomSeed;


    /**
     * Public Functions
     */
    /// @dev Contract initializer 
    /// @param _shipToken The token that is minted
    /// @param _legacyShipToken The legacy token that is upgradable to _token
    /// @param _beneficiary The address that receives the minting fees
    function initialize(address _shipToken, address _legacyShipToken, address payable _beneficiary) 
        public initializer 
    {
        require(_beneficiary != address(0), "Beneficiary cannot be zero address");

        __Ownable_init();
        shipToken = _shipToken;
        legacyShipToken = _legacyShipToken;
        beneficiary = _beneficiary;

        // Deal with legacy
        _upgradableSupply = IERC721EnumerableUpgradeable(
            _legacyShipToken).totalSupply();
        _currentTokenId = _upgradableSupply;

        // Set mintable ships
        mintData["Zephyr"] = MintData("Zephyr+", "Zephyr++");
        mintData["Cygnus"] = MintData("Cygnus+", "Cygnus++");
        mintData["Neptune"] = MintData("Neptune+", "Neptune++");
        mintData["Diogenes"] = MintData("Diogenes+", "Diogenes++");
        mintData["Cetus"] = MintData("Cetus+", "Cetus++"); 
        mintData["Manta"] = MintData("Manta+", "Manta++");
        mintData["Charybdis"] = MintData("Charybdis+", "Charybdis++");
        mintData["Tempest"] = MintData("Tempest+", "Tempest++"); 
        mintData["Osprey"] = MintData("Osprey+", "Osprey++");
        mintData["Trident"] = MintData("Trident+", "Trident++");
        mintData["Maelstrom"] = MintData("Maelstrom+", "Maelstrom++");
        mintData["Spartacus"] = MintData("Spartacus+", "Spartacus++");

        // Set special ships
        legacySpecial[1] = "Charlemagne++";
        legacySpecial[2] = "Olympus++";
        legacySpecial[3] = "Titan++";
        legacySpecial[4] = "Poseidon++";

        // Register as ERC777 recipient
        IERC1820RegistryUpgradeable(ERC1820_ADDRESS).setInterfaceImplementer(
            address(this), ERC777_RECIPIENT_INTERFACE, address(this));
    }


    /// @dev Returns the current token id
    /// @return uint The current token id
    function getCurrentTokenId() 
        public view returns (uint) 
    {
        return _currentTokenId;
    }


    /// @dev Set the beneficiary
    /// @param _beneficiary Funds are withdrawn to this account
    function setBeneficiary(address payable _beneficiary) 
        public onlyOwner 
    {
        require(_beneficiary != address(0), "Beneficiary cannot be zero address");
        beneficiary = _beneficiary;
    }


    /// @dev Set a referrer
    /// @param referrerName The name of the referrer
    /// @param referrerAddress The address of the referrer
    function setReferrer(bytes32 referrerName, address referrerAddress) 
        public onlyOwner 
    {
        require(referrerAddress != address(0), "Referrer cannot be zero address");
        referrers[referrerName] = referrerAddress;
    }


    /// @dev Set the legacy mintedAt timestamps
    /// @param tokenIds The tokenIds
    /// @param mintedAt The mintedAt timestamps
    function setLegacyMintedAt(uint[] memory tokenIds, uint128[] memory mintedAt) 
        public onlyOwner 
    {
        for (uint i = 0; i < tokenIds.length; i++) 
        {
            legacyMintedAt[tokenIds[i]] = mintedAt[i];
        }
    }


    /// @dev Upgrade legacy ships to new ships
    /// @notice We allow users to change their ship and skin when upgrading
    /// @param tokenIds The tokenIds
    /// @param ships The ships to mint (allows for ship changes)
    /// @param skins The skins to mint (allows for skin changes)
    function upgrade(uint[] memory tokenIds, bytes32[] memory ships, uint128[] memory skins) 
        public 
    {
        address sender = _msgSender();

        // Random
        bytes32 random = _random();
        bytes32 currentShip;
        uint currentScore;

        for (uint i = 0; i < tokenIds.length; i++) 
        {
            // Check if ship is mintable or special
            require(_canMintShip(ships[i]) || legacySpecial[tokenIds[i]] != bytes32(0), "Ship not mintable");

            // Check if ship is upgradable
            require(legacyMintedAt[tokenIds[i]] != 0, "Ship not upgradable");
            require(IERC721Upgradeable(legacyShipToken).ownerOf(tokenIds[i]) == sender, "Sender not owner");

            // Burn legacy ship
            IERC721Upgradeable(legacyShipToken).transferFrom(
                sender, address(this), tokenIds[i]);

            // Check if ship is special
            if (legacySpecial[tokenIds[i]] != bytes32(0)) 
            {
                currentShip = legacySpecial[tokenIds[i]];
            }
            else 
            {
                // Check if ship is rare or legendary
                currentScore = _randomAt(random, i);
                if (currentScore >= MIN_LEGENDARY_SCORE)
                {
                    currentShip = mintData[ships[i]].legendary;
                }
                else if (currentScore >= MIN_RARE_SCORE)
                {
                    currentShip = mintData[ships[i]].rare;
                }
                else 
                {
                    currentShip = ships[i];
                }
            }

            // Mint new ship
            ICryptopiaEarlyAccessShipToken(shipToken).mintTo(
                sender, tokenIds[i], currentShip, skins[i], legacyMintedAt[tokenIds[i]]);
        }
    }
    

    /// @dev Mint `ships` to `to`
    /// @param to The address of the recipient
    /// @param ships The ships to mint
    /// @param skins The skins to mint
    /// @param referrer The referrer (optional)
    function mint(address to, bytes32[] memory ships, uint128[] memory skins, bytes32 referrer) 
        public payable  
    {
        require(_canMint(ships.length), "Unable to mint items");
        require(_canPayMintFee(ships.length, msg.value), "Unable to pay");

        // Random
        bytes32 random = _random();
        bytes32 currentShip;
        uint currentScore;

        for (uint i = 0; i < ships.length; i++) 
        {
            // Check if ship is mintable
            require(_canMintShip(ships[i]), "Ship not mintable");

            // Check if ship is rare or legendary
            currentScore = _randomAt(random, i);
            if (currentScore >= MIN_LEGENDARY_SCORE)
            {
                currentShip = mintData[ships[i]].legendary;
            }
            else if (currentScore >= MIN_RARE_SCORE)
            {
                currentShip = mintData[ships[i]].rare;
            }
            else 
            {
                currentShip = ships[i];
            }

            // Mint ship
            ICryptopiaEarlyAccessShipToken(shipToken).mintTo(
                to, ++_currentTokenId, currentShip, skins[i], uint128(block.timestamp));
        }

        // Pay referrer
        if (referrer != bytes32(0)) 
        {
            require(referrers[referrer] != address(0), "Referrer not found");

            // Send ether to referrer
            (bool success, ) = payable(referrers[referrer])
                .call{value : ships.length * REFERAL_FEE}("");
            require(success, "Transfer to referrer failed");
        }
    }


    /// @dev Allows the owner to withdraw
    function withdraw() 
        public onlyOwner
    {
        (bool success, ) = beneficiary.call{value : address(this).balance}("");
        require(success, "Transfer to beneficiary failed");
    }


    /// @dev Failsafe mechanism
    /// Allows the owner to retrieve tokens from the contract that 
    /// might have been send there by accident
    /// @param tokenContract The address of ERC20 compatible token
    function retrieveTokens(IERC20Upgradeable tokenContract) 
        public virtual override 
        onlyOwner
    {
        super.retrieveTokens(tokenContract);
    }


    /// @dev See {IERC721Receiver-onERC721Received}.
    /// Always returns `IERC721Receiver.onERC721Received.selector`.
    function onERC721Received(address, address, uint256, bytes memory) 
        public virtual override 
        returns (bytes4) 
    {
        return this.onERC721Received.selector;
    }


    /**
     * Internal Functions
     */
    /// @dev Returns if it's still possible to mint `_numberOfItemsToMint`
    /// @param _numberOfItemsToMint Number of items to mint
    /// @return bool True if the items can be minted
    function _canMint(uint _numberOfItemsToMint) 
        internal view 
        returns (bool) 
    {
        // Enforce max token rule
        return _currentTokenId <= (MAX_SUPPLY - _numberOfItemsToMint);
    }


    /// @dev Returns if the ship can be minted
    /// @param _ship The ship to mint
    /// @return bool True if the ship can be minted
    function _canMintShip(bytes32 _ship) 
        internal view 
        returns (bool) 
    {
        return mintData[_ship].rare != bytes32(0);
    }


    /// @dev Returns if the call has enough ether to pay the minting fee
    /// @param _numberOfItemsToMint Number of items to mint
    /// @param _received The amount that was received
    /// @return bool True if the mint fee can be payed
    function _canPayMintFee(uint _numberOfItemsToMint, uint _received) 
        internal pure 
        returns (bool) 
    {
        return _received >= _getMintFee(_numberOfItemsToMint);
    }


    /// @dev Returns the ether amount needed to pay the minting fee
    /// @param _numberOfItemsToMint Number of items to mint
    /// @return uint amount needed to pay the minting fee
    function _getMintFee(uint _numberOfItemsToMint) 
        internal pure 
        returns (uint) 
    {
        return MINT_FEE * _numberOfItemsToMint;
    }


    /// @dev Pseudo-random hash generator
    /// @notice This is not secure, but it's good enough for our use case
    /// @return bytes32 Random hash
    function _random() 
        internal 
        returns(bytes32) 
    {
        _currentRandomSeed = keccak256(
            abi.encodePacked(blockhash(block.number - 1), 
            _msgSender(), 
            _currentRandomSeed));
        return _currentRandomSeed;
    }


    /// @dev Get a number from a random `seed` at `index`
    /// @param _hash Randomly generated hash 
    /// @param index Used as salt
    /// @return uint32 Random number
    function _randomAt(bytes32 _hash, uint index) 
        private pure 
        returns(uint32) 
    {
        return uint32(uint(keccak256(abi.encodePacked(_hash, index))) % INVERSE_BASIS_POINT);
    }
}