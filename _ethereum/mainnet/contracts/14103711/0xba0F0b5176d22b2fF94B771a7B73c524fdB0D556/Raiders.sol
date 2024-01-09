//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "ERC721Enumerable.sol";
import "Ownable.sol";
import "ReentrancyGuard.sol";
import "IRaider.sol";
import "IRaiderGold.sol";
import "IRaiderHunt.sol";
import "IRaiderRender.sol";
import "IRaiderArmory.sol";

contract Raiders is Ownable, ERC721Enumerable, ReentrancyGuard {
    // price of a single token
    uint256 public constant PRESALE_PRICE = 0.045 ether;
    uint256 public constant PUBLIC_PRICE = 0.055 ether;
    // max supply of tokens
    uint256 public constant SUPPLY = 10000;
    // max tokens mintable per tx in public sale
    uint256 public constant MAX_PER_TX = 10;
    // max dev supply for give aways, team, advisors
    uint256 public constant DEV_SUPPLY = 30;
    // max public supply (total supply - gifts)
    uint256 public constant PUBLIC_SUPPLY = SUPPLY - DEV_SUPPLY;
    // max tokens mintable per tx/total in presale
    uint256 public constant MAX_PRESALE_AMOUNT = 5;
    // presale slots available
    uint256 public constant PRESALE_SLOTS = 700;
    // max supply for presale
    uint256 public constant PRESALE_SUPPLY = MAX_PRESALE_AMOUNT * PRESALE_SLOTS;
    // number of tokens minted so far
    uint256 public minted;
    // numer of tokens presold so far
    uint256 public presaleMinted;
    // digits and modulus for raider dna
    uint256 private constant dnaDigits = 18;
    uint256 private constant dnaModulus = 10**dnaDigits;
    // presale live switch
    bool public isPresaleLive;
    // sale live switch
    bool public isSaleLive;

    // mapping of existing dnas
    mapping(uint256 => bool) private existingDnas;
    // raiders
    mapping(uint256 => IRaider.Raider) public raiders;
    // presale mapping
    mapping(address => bool) public presaleAllowList;
    // presale mints
    mapping(address => uint256) public presaleAddressToAmountMinted;

    // reference to $RGO
    IRaiderGold private rgo;
    // reference to staking
    IRaiderHunt private hunt;
    // reference to armory
    IRaiderArmory private armory;
    // reference to renderer
    IRaiderRender private render;

    // instantiates contract
    constructor(address _raiderGoldAddress, address _renderAddress)
        ERC721("Raiderverse Genesis", "Raiders")
    {
        rgo = IRaiderGold(_raiderGoldAddress);
        render = IRaiderRender(_renderAddress);
    }

    /*************/
    /* MODIFIERS */
    /*************/

    modifier callerIsUser() {
        require(msg.sender == tx.origin, "Caller is contract");
        _;
    }

    /************/
    /* EXTERNAL */
    /************/

    /**
     * @notice mints one or multiple tokens up to max token amount per tx to an address
     * @param _amount - number of tokens to mint
     */
    function mint(uint256 _amount) public payable callerIsUser {
        require(isSaleLive, "Not live");
        require(msg.value == PUBLIC_PRICE * _amount, "Bad value");
        require(_amount > 0 && _amount <= MAX_PER_TX, "Bad amount");
        require(minted + _amount <= PUBLIC_SUPPLY, "Exceeds supply");

        for (uint256 i = 0; i < _amount; i++) {
            minted++;
            registerRaider(minted, msg.sender);
            _safeMint(msg.sender, minted);
        }
    }

    /**
     * @notice mints one or multiple tokens up to max token amount per tx to an address for presale
     * @param _amount - number of tokens to mint
     */
    function presaleMint(uint256 _amount) public payable callerIsUser {
        require(isPresaleLive, "Not live");
        require(presaleAllowList[msg.sender], "Not allowed");
        require(msg.value == PRESALE_PRICE * _amount, "Bad value");
        require(_amount > 0 && _amount <= MAX_PRESALE_AMOUNT, "Bad amount");
        require(
            presaleAddressToAmountMinted[msg.sender] + _amount <=
                MAX_PRESALE_AMOUNT,
            "Exceeds alloc"
        );
        require(presaleMinted + _amount <= PRESALE_SUPPLY, "Exceeds supply");

        for (uint256 i = 0; i < _amount; i++) {
            minted++;
            presaleMinted++;
            presaleAddressToAmountMinted[msg.sender]++;
            registerRaider(minted, msg.sender);
            _safeMint(msg.sender, minted);
        }
    }

    /**
     * @notice fetches raider information
     * @param _tokenId - the tokenId of the raider to fetch
     * @return the raider struct
     */
    function getTokenRaider(uint256 _tokenId)
        public
        view
        returns (IRaider.Raider memory)
    {
        return raiders[_tokenId];
    }

    /**
     * @notice update a token's active weapon
     * @param _tokenId - the token's id
     * @param _weaponId - the desired weapon's id
     */
    function updateActiveWeapon(uint256 _tokenId, uint256 _weaponId) public {
        require(
            msg.sender == ownerOf(_tokenId) ||
                hunt.isStaker(msg.sender, _tokenId),
            "Not allowed"
        );
        require(armory.hasWeapon(_tokenId, _weaponId), "Not your weapon");
        
        IRaider.Raider storage r = raiders[_tokenId];
        r.active_weapon = _weaponId;
    }

    /************/
    /* INTERNAL */
    /************/

    /**
     * @notice creates a raider
     * @dev multiple things packed in here to save gas
     * @param _tokenId - the tokenId of the raider
     * @param _address - the address to mint to raider to
     */
    function registerRaider(uint256 _tokenId, address _address) private {
        uint256 dna = uint256(
            keccak256(
                abi.encodePacked(
                    _tokenId,
                    _address,
                    block.difficulty,
                    block.timestamp
                )
            )
        ) % dnaModulus;
        if (existingDnas[dna]) {
            registerRaider(_tokenId, _address);
        } else {
            uint256 active_weapon = ((dna / (100**8)) % 8);
            raiders[_tokenId] = IRaider.Raider({
                dna: dna,
                active_weapon: active_weapon
            });
            armory.addWeaponToToken(_tokenId, active_weapon);
        }
    }

    /*********/
    /* OWNER */
    /*********/

    /**
     * @notice flips sale status (default is false)
     */
    function flipSaleStatus() external onlyOwner {
        isSaleLive = !isSaleLive;
    }

    /**
     * @notice flips presale status (default is false)
     */
    function flipPresaleStatus() external onlyOwner {
        isPresaleLive = !isPresaleLive;
    }

    /**
     * @notice adds delegate callers
     * @param _raiderHuntAddress - address of RaiderHunt contract
     * @param _raiderArmoryAddress - address of RaiderArmory contract
     */
    function addDelegates(
        address _raiderHuntAddress,
        address _raiderArmoryAddress
    ) external onlyOwner {
        hunt = IRaiderHunt(_raiderHuntAddress);
        armory = IRaiderArmory(_raiderArmoryAddress);
    }

    /**
     * @notice updates render contract address
     * @dev e.g. when we want to switch to off-chain render for Twitter
     * @param _address the new render contract address
     */
     function updateRender(address _address) external onlyOwner {
         render = IRaiderRender(_address);
     }

    /**
     * @notice adds address(es) to presale allowlist
     * @param _addresses - array of addresses to allow for presale
     */
    function addToPresaleAllowlist(address[] calldata _addresses)
        external
        onlyOwner
    {
        require(
            _addresses.length != 0 && _addresses.length <= PRESALE_SLOTS,
            "Bad amount"
        );
        for (uint256 i = 0; i < _addresses.length; i++) {
            presaleAllowList[_addresses[i]] = true;
        }
    }

    /**
     * @notice allows owner to mint tokens anytime
     * @param _amount - the amount of tokens to mint
     */
    function devMint(uint256 _amount) external onlyOwner {
        require(_amount > 0 && minted + _amount <= SUPPLY, "Bad amount");

        for (uint256 i = 0; i < _amount; i++) {
            minted++;
            registerRaider(minted, msg.sender);
            _safeMint(msg.sender, minted);
        }
    }

    /**
     * @notice allows owner to withdraw funds from minting
     */
    function withdraw() external onlyOwner nonReentrant {
        require(address(this).balance != 0, "No funds");
        payable(msg.sender).transfer(address(this).balance);
    }

    /**********/
    /* RENDER */
    /**********/

    /**
     * @notice returns token URI
     * @param tokenId - the id of the token to return URI for
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
        return render.tokenURI(tokenId);
    }
}
