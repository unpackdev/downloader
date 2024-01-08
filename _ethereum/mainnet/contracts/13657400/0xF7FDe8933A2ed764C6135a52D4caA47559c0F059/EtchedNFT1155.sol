// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/// @title NFT contract for Etched based on OpenZeppelin's ERC1155 implementation
/// @author Linum Labs
/// @dev Includes implementation of ERC2981 (Royalty Standard)

import "./ERC1155.sol";
import "./ERC165Storage.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./IERC2981.sol";

contract EtchedNFT1155 is ERC1155, ERC165Storage, Ownable, IERC2981 {
    using Counters for Counters.Counter;

    Counters.Counter private _id;

    // royalty rate vars
    // scale: how many zeroes should follow the royalty rate
    // in the default values, there would be a 10% tax on a 18 decimal asset
    uint256 private rate = 10_000;
    uint256 private scale = 1e5;

    mapping(uint256 => string) private _tokenURIs;
    mapping(uint256 => address) private _creators;
    mapping(uint256 => uint256) private _totalSupply;
    // id => user => if they're a minter
    mapping(address => bool) private minters;

    event TokenURI(
        uint256 indexed id,
        string tokenUri,
        uint256 amount,
        address creator,
        address owner
    );
    event RoyaltyRateSet(uint256 indexed rate, uint256 indexed scale);
    event MinterUpdated(
        address indexed minter,
        bool indexed canMint,
        string userIdentifier
    );
    event CapSet(uint256 indexed id, uint256 indexed cap);

    constructor() ERC1155("") {
        ERC165Storage._registerInterface(type(IERC2981).interfaceId);
        ERC165Storage._registerInterface(type(IERC1155).interfaceId);
        ERC165Storage._registerInterface(type(IERC1155MetadataURI).interfaceId);

        // ids 1,2 reserved for airdrop
        _id.increment();
        _id.increment();

        // hardcoding for HDA airdrop
        _creators[1] = address(0xeb7b2f62BFBac835CCb3e1ddE38CE79D89a8445C);
        _tokenURIs[1] = "QmT4RVQwvY8tghLa2HzZEFvEGxNRsZf3Fxb8byooMK6Ff4";

        // hardcoding for founder's key
        _creators[2] = address(0xeb7b2f62BFBac835CCb3e1ddE38CE79D89a8445C);
        _tokenURIs[2] = "QmWrhHtZLEkUg46MjjkyhYW8uuijPm89842CcRTeHxUJ6j";
    }

    /// @notice Queries the URI of an NFT
    /// @param id the index of the NFT to query
    /// @return the URI string of the NFT
    function uri(uint256 id) public view override returns (string memory) {
        return _tokenURIs[id];
    }

    /// @notice Queries the supply of a particular NFT
    /// @param id the index of the NFT to query the supply of
    /// @return the total number of NFTs in circulation for this NFT
    function totalSupply(uint256 id) external view returns (uint256) {
        require(id <= _id.current(), "id has not been minted");
        return _totalSupply[id];
    }

    /// @notice Given an NFT and the amount of a price, returns pertinent royalty information
    /// @dev This function is specified in EIP-2981
    /// @param id the index of the NFT to calculate royalties on
    /// @param _salePrice the amount the NFT is being sold for
    /// @return the address to send the royalties to, and the amount to send
    function royaltyInfo(uint256 id, uint256 _salePrice)
        external
        view
        override
        returns (address, uint256)
    {
        require(_exists(id), "royaltyInfo: nonexistent token");
        uint256 royaltyAmount = (_salePrice * rate) / scale;
        return (getCreator(id), royaltyAmount);
    }

    /// @notice gets the global royalty rate
    /// @dev divide rate by scale to get the percentage taken as royalties
    /// @return a tuple of (rate, scale)
    function getRoyaltyRate() external view returns (uint256, uint256) {
        return (rate, scale);
    }

    /// @notice Queries if an address is allowed to mint
    /// @param minter the address to check
    /// @return bool if the address is a minter or not
    function isMinter(address minter) external view returns (bool) {
        return minters[minter];
    }

    /// @notice gets the address of a creator for an NFT
    /// @dev The first 450 tokenIds are reserved for the HDA airdrop
    /// @param id the index of the NFT to return the creator of
    /// @return the address of the creator
    function getCreator(uint256 id) public view returns (address) {
        require(_exists(id), "getCreator: nonexistent token");
        return _creators[id];
    }

    /// @notice Sets the global variables relating to royalties
    /// @param _rate the amount, that when adjusted with the scale, represents the royalty rate
    /// @param _scale the amount of decimal places to scale the rate when applying
    /// example: given an 18-decimal currency, a rate of 5 with a scale of 1e16 would be 5%
    /// since this is 0.05 to an 18-decimal currency
    function setRoyaltyRate(uint256 _rate, uint256 _scale) external onlyOwner {
        rate = _rate;
        scale = _scale;
        emit RoyaltyRateSet(_rate, _scale);
    }

    /// @notice Allows contract owner to add or remove minters to a specific id
    /// @param minter the address to update
    /// @param canMint the status the address should be set to
    function setMinter(
        address minter,
        bool canMint,
        string calldata userIdentifier
    ) external onlyOwner {
        minters[minter] = canMint;
        emit MinterUpdated(minter, canMint, userIdentifier);
    }

    /// @notice Allows a whitelisted address to mint a single NFT
    /// @param creator the address to be recorded as the NFT's creator
    /// @param to the address to mint the NFT to
    /// @param amount the amount of NFTs to mint
    /// @param tokenUri the IPFS hash of the NFT metadata
    function mint(
        address creator,
        address to,
        uint256 amount,
        string memory tokenUri
    ) external {
        _id.increment();
        uint256 id = _id.current();
        require(
            minters[msg.sender] == true || msg.sender == owner(),
            "unauthorized minter"
        );
        _mint(to, id, amount, "");
        _totalSupply[id] = amount;
        _tokenURIs[id] = tokenUri;
        _creators[id] = creator;
        emit TokenURI(id, tokenUri, amount, creator, to);
    }

    /// @notice batch mint function
    /// @dev can only be called by owner, will mint all NFTs to one address for distribution
    /// @param to the address to mint all NFTs to
    /// @param creators an ordered array of the addresses to list as creators for each NFT
    /// @param amounts an ordered array of the amount of each NFT to mint
    /// @param uris the uri of each NFT being minted
    function mintBatch(
        address to,
        address[] memory creators,
        uint256[] memory amounts,
        string[] memory uris
    ) external onlyOwner {
        uint256 len = amounts.length;
        uint256[] memory ids = new uint256[](len);
        for (uint256 i = 0; i < len; i++) {
            _id.increment();
            uint256 tokenId = _id.current();
            ids[i] = tokenId;
        }
        _mintBatch(to, ids, amounts, "");
        for (uint256 i = 0; i < len; i++) {
            _tokenURIs[ids[i]] = uris[i];
            _creators[ids[i]] = creators[i];
            _totalSupply[ids[i]] = amounts[i];
            emit TokenURI(ids[i], uris[i], amounts[i], _creators[ids[i]], to);
        }
    }

    /// @notice Bespoke function for airdropping the HDA NFT and founder's key
    /// @dev Cycles through an array of addresses and mints
    /// @param id 1 (HDA) or 2(Founder's Key)
    /// @param to an array of addresses to send the NFT to
    /// @param amount the amount to send to the corresponding address in `to`
    function airdrop(
        uint256 id,
        address[] memory to,
        uint256[] memory amount
    ) external onlyOwner {
        require(id == 1 || id == 2, "only ids 1,2 can be airdropped");
        // HDA cap: 450, founder's key cap: 75
        uint256 cap = id == 1 ? 450 : 75;
        uint256 len = to.length;
        require(len == amount.length, "arrays must have equal length");
        for (uint256 i = 0; i < len; i++) {
            uint256 amt = amount[i];
            require(_totalSupply[id] + amt <= cap, "airdrop exceeds cap");
            address _to = to[i];
            _totalSupply[id] += amt;
            _mint(_to, id, amt, "");
        }
    }

    /// @dev returns true if this contract implements the interface defined by `interfaceId`
    /// @dev for more on interface ids, see https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165Storage, IERC165, ERC1155)
        returns (bool)
    {
        return ERC165Storage.supportsInterface(interfaceId);
    }

    function _exists(uint256 id) internal view returns (bool) {
        return
            _totalSupply[id] > 0 ||
            _creators[id] != address(0) ||
            keccak256(bytes(_tokenURIs[id])) != "";
    }
}
