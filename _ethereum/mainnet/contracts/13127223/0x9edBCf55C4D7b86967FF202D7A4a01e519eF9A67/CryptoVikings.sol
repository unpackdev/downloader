// SPDX-License-Identifier: CC-BY-SA-4.0
pragma solidity >=0.7.0 <0.9.0;
pragma abicoder v2;

import "./console.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Enumerable.sol";
import "./ECDSA.sol";
import "./draft-EIP712.sol";

/**
 * @title CryptoVikings
 * @dev CryptoVikings -  A contract for non-fungible Vikings
 **/
contract CryptoVikings is ERC721URIStorage, EIP712, Ownable {
    struct NFTVoucher {
        uint256 tokenId;
        uint256 minPrice;
        string uri;
        bytes signature;
    }

    event PermanentURI(string _value, uint256 indexed _id); // Opensea Metadata Freezing

    string private constant SIGNING_DOMAIN = "Viking-Voucher";
    string private constant SIGNATURE_VERSION = "1";

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 private constant MAX_SUPPLY = 10000;

    mapping(address => uint256) private pendingWithdrawals;

    //Define id->name mapping
    mapping(uint256 => string) private _vikingNamesById;

    //Define name->id mapping
    mapping(string => uint256) private _vikingIdsByName;

    constructor (address payable minter)
        ERC721("CryptoVikings", "CVK")
        EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION)
    {}

    //Supply this even though we are not a real ERC20,, but we do have max supply
    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        return MAX_SUPPLY;
    }

    //Returns  wheter a Viking has been minted
    function isMinted(uint256 tokenId) public view virtual returns (bool) {
        if (_exists(tokenId)) {
            return (true);
        } else {
            return (false);
        }
    }

    /**
     * @dev Get token id's of all minted assets
     *
     */
    function getMintedIds() public view returns (uint256[] memory) {
        uint256 index = 0;
        uint256[] memory mintedIds = new uint256[](_tokenIds.current());
        for (uint256 tokenId = 1; tokenId <= MAX_SUPPLY; tokenId++) {
            if (_exists(tokenId)) {
                mintedIds[index] = tokenId;
                index++;
            }
        }
        return mintedIds;
    }

    //Return token id's of all Vikings owned by provided address
    function getOwnedIds(address owner) public view returns (uint256[] memory) {
        uint256 index = 0;
        uint256[] memory ownerIds = new uint256[](balanceOf(owner));
        for (uint256 tokenId = 1; tokenId <= MAX_SUPPLY; tokenId++) {
            if (_exists(tokenId)) {
                if (ownerOf(tokenId) == owner) {
                    ownerIds[index] = tokenId;
                    index++;
                }
            }
        }
        return ownerIds;
    }

    /**
     * Returns real name of Viking
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */

    function getVikingName(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "Viking not found");
        string memory name = "";
        name = _vikingNamesById[tokenId];
        return (name);
    }

    /**
     * @dev Set the reak name of a Viking
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function setVikingName(uint256 tokenId, string memory _name) public {
        require(_exists(tokenId), "Viking not found");
        require(ownerOf(tokenId) == _msgSender(), "Caller is not the owner");
        require(_tokenIds.current() < MAX_SUPPLY, "Maximum amount of tokens minted");
        string memory name;
        name = _vikingNamesById[tokenId];
        require(bytes(name).length == 0, "Viking name allready set");

        if (_vikingIdsByName[_name] != 0) {
            //Viking name not set
            require(_vikingIdsByName[_name] == tokenId, "Viking name allready used");
        }
        _vikingNamesById[tokenId] = _name;
        _vikingIdsByName[_name] = tokenId;
    }


    /**
     * Mint a Viking by redeeming proided voucher
     *
     * Requirements:
     *
     * - `voucher` must must be valid
     */
    function redeem(address redeemer, NFTVoucher calldata voucher)
        public
        payable
        returns (uint256)
    {
        // enforce maximum supply policy
        require(_tokenIds.current() < MAX_SUPPLY, "Maximum amount of tokens minted");
        _tokenIds.increment();

        // make sure signature is valid and get the address of the signer
        address signer = _verify(voucher);

        // make sure that the signer is authorized to mint NFTs
        require(signer == owner(), "Signature invalid");

        // make sure that the redeemer is paying enough to cover the buyer's cost
        require(msg.value >= voucher.minPrice, "Insufficient funds to redeem");

        // first assign the token to the signer, to establish provenance on-chain
        _mint(signer, voucher.tokenId);

        _setTokenURI(voucher.tokenId, voucher.uri);

        emit PermanentURI(voucher.uri, voucher.tokenId);

        // transfer the token to the redeemer
        _transfer(signer, redeemer, voucher.tokenId);

        // record payment to signer's withdrawal balance
        pendingWithdrawals[signer] += msg.value;

        return voucher.tokenId;
    }

    /**
     * @dev Get token metadata uri
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Viking not found");

        string memory _tokenURI = super.tokenURI(tokenId);
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        return super.tokenURI(tokenId);
    }

    /**
     * Withdraw balance
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function withdraw() public onlyOwner {
        address payable receiver = payable(msg.sender);

        uint256 amount = pendingWithdrawals[receiver];

        // zero account before transfer to prevent re-entrancy attack
        pendingWithdrawals[receiver] = 0;
        receiver.transfer(amount);
    }

    /**
     * Return quantity of minted Vikings
     */
    function quantityMinted() public view returns (uint256) {
        return _tokenIds.current();
    }

    /**
     * Get balance available to withdraw
     */
    function availableToWithdraw() public view onlyOwner returns (uint256) {
        return pendingWithdrawals[msg.sender];
    }

    /**
     * Verify voucher signature
     *
     * Requirements:
     *
     * - `voucher` must must be a redeemable voucher.
     */
    function _verify(NFTVoucher calldata voucher) internal view returns (address) {
        bytes32 digest = _hash(voucher);
        return ECDSA.recover(digest, voucher.signature);
    }

    function _hash(NFTVoucher calldata voucher) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256("NFTVoucher(uint256 tokenId,uint256 minPrice,string uri)"),
                        voucher.tokenId,
                        voucher.minPrice,
                        keccak256(bytes(voucher.uri))
                    )
                )
            );
    }

    /**
     * Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override {
        require(_exists(tokenId), "Viking not found");
        super._burn(tokenId);
    }

    /**
     * @dev Utility function to return correct chain Id
     */
    function getChainID() external view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

}
