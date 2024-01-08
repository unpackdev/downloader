//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./Counters.sol";
import "./ERC721.sol";
import "./Frens.sol";


/*
  _   _               _____                  _ _     _        _____
 | \ | | ___  _ __   |  ___|   _ _ __   __ _(_) |__ | | ___  |  ___| __ ___ _ __  ___
 |  \| |/ _ \| '_ \  | |_ | | | | '_ \ / _` | | '_ \| |/ _ \ | |_ | '__/ _ \ '_ \/ __|
 | |\  | (_) | | | | |  _|| |_| | | | | (_| | | |_) | |  __/ |  _|| | |  __/ | | \__ \
 |_| \_|\___/|_| |_| |_|   \__,_|_| |_|\__, |_|_.__/|_|\___| |_|  |_|  \___|_| |_|___/
                                       |___/
*/

contract NonFungibleFrens is ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    struct Traits {
        string traitName;
        uint8 traitValue;
    }

    bool _pauseContract = true;
    mapping(address => bool) whitelisted;
    mapping(address => bool) allowedAddress;
    mapping(address => uint8) maxTokensPerWallet;
    mapping(uint => Traits) public traitTypes;
    address public owner;
    string imageURI;
    string animationURI;
    uint SEED;
    uint maxValueProp = 100;

    /**
    * @dev onlyOwner modifier
    */
    modifier onlyOwner
    {
        require(msg.sender == owner, "NFF: You are not the owner");
        _;
    }

    /**
    * @dev whitelisting modifier
    */
    modifier onlyWhitelisted
    {
        require(whitelisted[msg.sender] == true, "NFF: You are not whitelisted");
        _;
    }

    /**
    * @dev onlyAllowedAddress modifier
    */
    modifier onlyAllowedAddress {
        require(allowedAddress[msg.sender] == true, "NFF: You are not allowed to call this function");
        _;
    }

    /*
     __  __ _       _   _               _____                 _   _
    |  \/  (_)_ __ | |_(_)_ __   __ _  |  ___|   _ _ __   ___| |_(_) ___  _ __  ___
    | |\/| | | '_ \| __| | '_ \ / _` | | |_ | | | | '_ \ / __| __| |/ _ \| '_ \/ __|
    | |  | | | | | | |_| | | | | (_| | |  _|| |_| | | | | (__| |_| | (_) | | | \__ \
    |_|  |_|_|_| |_|\__|_|_| |_|\__, | |_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
                                |___/
    */

    /**
    * @dev function to claim the Frens NFT
    */
    function claimNFF()
        external
        onlyWhitelisted
    {
        //validation before minting
        require(
            maxTokensPerWallet[msg.sender] == 0,
            "NFF: You are not allowed to mint anymore tokens"
        );
        require(
            _pauseContract == false,
             "NFF: Contract is paused!"
        );

        maxTokensPerWallet[msg.sender] += 1;
        setTraitName(_tokenIds.current());
        setTraitValue(_tokenIds.current());
        _safeMint(msg.sender, _tokenIds.current());
        _tokenIds.increment();
    }

    /**
    * @dev override the tokenURI and generate the metadata on-chain
    */
    function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
    {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    return
        string(
            abi.encodePacked(
                "data:application/json;base64,",
                FrensLib.encode(
                    bytes(
                        string(
                            abi.encodePacked(
                                '{"name": "Non Fungible Frens Cartridge #',
                                FrensLib.toString(tokenId),
                                '","description": "The NFF genesis cartridge permits access to the Frens Discord restricted channels. Each holder is entitled to a vote in the governance of the Non Fungible Frens DAO.", "image":"',
                                imageURI,
                                '","animation_url":"',
                                animationURI,
                                '","attributes":',
                                hashToMetadata(tokenId),
                                "}"
                            )
                        )
                    )
                )
            )
        );
    }

    /**
    * @dev generate the attributes metadata for the tokenURI
    */
    function hashToMetadata(uint _tokenId)
        public
        view
        returns (string memory)
    {
        string memory metadataString;

            metadataString = string(
                abi.encodePacked(
                    metadataString,
                    '{"trait_type":"',
                    traitTypes[_tokenId].traitName,
                    '","max_value":',
                    FrensLib.toString(maxValueProp),
                    ',"value":',
                    FrensLib.toString(getFriendshipLvl(_tokenId)),
                    '}'
                )
            );

        return string(abi.encodePacked("[", metadataString,"]"));
    }

    /*
  ____       _   _
 / ___|  ___| |_| |_ ___ _ __ ___
 \___ \ / _ \ __| __/ _ \ '__/ __|
  ___) |  __/ |_| ||  __/ |  \__ \
 |____/ \___|\__|\__\___|_|  |___/

    */

    /**
    * @dev set the Image URI used for the metadata
    */
    function setImageURI(string memory _imageURI)
        public
        onlyOwner
    {
        imageURI = _imageURI;
    }

    /**
    * @dev set the Animation URI used for the metadata
    */
    function setAnimationURI(string memory _animationURI)
        public
        onlyOwner
    {
        animationURI = _animationURI;
    }

    /**
    * @dev set the name of the trait used in the metadata
    */
    function setTraitName(uint _tokenId)
        internal
    {
        traitTypes[_tokenId].traitName = "Friendship";
    }

    /**
    * @dev set the initial lvl value for the trait
    */
    function setTraitValue(uint _tokenId)
        internal
    {
        SEED++;
        uint tempValue = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.difficulty,
                    _tokenId,
                    msg.sender,
                    SEED
                )
            )
        ) % 100;

        if (tempValue == 0) tempValue = 1;

        traitTypes[_tokenId].traitValue = uint8(tempValue);
    }

    /**
    * @dev set the allowed addresses to interact with specific functions
    */
    function setAllowedAddress (address _addr)
        public
        onlyOwner
    {
        allowedAddress[_addr] = true;
    }

    /**
    * @dev set whitelisted for multiple wallets at a time. Only owner
    */
    function setMultipleWhitelist(address[] memory _whitelistAddr)
        public
        onlyOwner
    {
        for (uint i = 0; i < _whitelistAddr.length; i++)
        {
            whitelisted[_whitelistAddr[i]] = true;
        }
    }

    /**
    * @dev set whitelisted for a single wallet. Only owner
    */
    function setWhitelist(address _whitelistAddr)
        public
        onlyOwner
    {
        whitelisted[_whitelistAddr] = true;
    }

    /**
    * @dev set the update the lvl value
    */
    function updateTraitValue(uint _tokenId, uint8 _newValue)
        public
        onlyAllowedAddress
    {
        traitTypes[_tokenId].traitValue = _newValue;
    }

    /*
   ____      _   _
  / ___| ___| |_| |_ ___ _ __ ___
 | |  _ / _ \ __| __/ _ \ '__/ __|
 | |_| |  __/ |_| ||  __/ |  \__ \
  \____|\___|\__|\__\___|_|  |___/

    */

    /**
    * @dev set the update the lvl value
    */
    function getFriendshipLvl(uint _tokenId)
        public
        view
        returns(uint8)
    {
        return traitTypes[_tokenId].traitValue;
    }

    /**
    * @dev set the update the lvl value
    */
    function getTraitName(uint _tokenId)
        public
        view
        returns(string memory)
    {
        return traitTypes[_tokenId].traitName;
    }

    /**
    * @dev Get the current ID to mint / totalSupply minted
    */
    function totalSupply()
        public
        view
        returns (uint)
    {
      return _tokenIds.current() - 1;
    }

    /*
   ___                             _____                 _   _
  / _ \__      ___ __   ___ _ __  |  ___|   _ _ __   ___| |_(_) ___  _ __  ___
 | | | \ \ /\ / / '_ \ / _ \ '__| | |_ | | | | '_ \ / __| __| |/ _ \| '_ \/ __|
 | |_| |\ V  V /| | | |  __/ |    |  _|| |_| | | | | (__| |_| | (_) | | | \__ \
  \___/  \_/\_/ |_| |_|\___|_|    |_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/

    */

    /**
    * @dev function to unpause the smart contract
    */
    function pauseContract()
        public
        onlyOwner
    {
        _pauseContract = !_pauseContract;
    }

    /**
    * @dev change ownership for the multisig wallet
    */
    function changeOwnership(address _newOwner)
        public
        onlyOwner
    {
        owner = _newOwner;
    }

   constructor (string memory _imageURI, string memory _animationURI) ERC721 ("NonFungibleFrens", "NFF")
    {
        owner = msg.sender;
        imageURI = _imageURI;
        animationURI = _animationURI;
        _tokenIds.increment();
    }
}
