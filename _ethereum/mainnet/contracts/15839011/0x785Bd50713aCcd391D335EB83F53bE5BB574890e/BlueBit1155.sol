// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "./ERC1155Burnable.sol";
import "./ERC1155Supply.sol";
import "./Context.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./AccessControl.sol";

//@dev see{ERC1155Supply, ERC1155Burnable, Context, Counters, AccessControl}.

contract BlueBit1155 is
    Context,
    ERC1155Burnable,
    ERC1155Supply,
    AccessControl
{
    //@notice Counters used for tokenId iteration.
    //@dev see {Counters}.
    using Counters for Counters.Counter;
    using Strings for uint256;
    //@notice _tokenIdTracker holds the current counter value.
    Counters.Counter private _tokenIdTracker;

    mapping(uint256 => string) private _tokenURIs;

    //@notice usedNonce is an array value used for duplicate sign restriction.

    mapping(uint256 => bool) private usedNonce;

    //@notice operator holds current contract operator.

    address public operator;

    //@notice TokenRoyalty is an array value used for storing Royalty info.
    //@dev see{TokenRoyalty}.

    mapping(uint256 => TokenRoyalty) private tokenRoyalty;


    //@notice Sign struct stores the sign bytes
    //@param v it holds(129-130) from sign value length always 27/28.
    //@param r it holds(0-66) from sign value length.
    //@param s it holds(67-128) from sign value length.
    //@param nonce unique value.

    struct Sign {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 nonce;
    }

    //@notice TokenRoyalty for holding each NFTsTokenRoyalty info.
    //@param royaltyPermiles array of royaltyFee permiles.
    //@param receivers array of royalty receivers.

    struct TokenRoyalty {
        uint96[] royaltyPermiles;
        address[] receivers;
    }

    //@notice baseTokenURI holds the IPFS target file URL.

    string private baseTokenURI;

    //@notice _name holds the NFT contract name.

    string private _name;

    //@notice _symbol holds the NFT contract symbol.

    string private _symbol;

    //@notice owner holds current contract owner.

    address public owner;

    //@notice OwnershipTransferred the event is emited at the time of transferownership function invoke.
    //@param previousOwner address of the previous contract owner.
    //@param newOwner address of the new contract owner.

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    //@notice BaseURIChanged the event is emited at the time of setBaseURI function invoke.
    //@param uri address of the previous ipfs target uri.
    //@param newuri address of the new ipfs target uri.

    event BaseURIChanged(
        string indexed uri,
        string indexed newuri
    );

    event OperatorUpdated(
        address indexed previousOperator,
        address indexed newOperator
    );

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        string memory _baseTokenURI,
        address _operator
    ) ERC1155(_baseTokenURI) {
        baseTokenURI = _baseTokenURI;
        owner = _msgSender();
        operator = _operator;
        _setupRole("ADMIN_ROLE", msg.sender);
        _setupRole("OPERATOR_ROLE", operator);
        _name = _tokenName;
        _symbol = _tokenSymbol;
        _tokenIdTracker.increment();
    }

    //@notice name the view function returns the name of NFT contract.
    //@return _name name of NFT contract.

    function name() external view returns (string memory) {
        return _name;
    }

    //@notice symbol the view function returns the name of NFT contract.
    //@return _symbol symbol of NFT contract.

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    //@notice transferOwnership for transferring contract ownership to new owner address.
    //@param newOwner address of new owner.
    //@return bool value always true.
    /** restriction: the ADMIN_ROLE address only has the permission to
        transfer the contract ownership to new wallet address.*/
    //@dev see{Accesscontrol}.
    // emits {OwnershipTransferred} event.

    function transferOwnership(address newOwner)
        external
        onlyRole("ADMIN_ROLE")
        returns (bool)
    {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _revokeRole("ADMIN_ROLE", owner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        _setupRole("ADMIN_ROLE", newOwner);
        return true;
    }

    //@notice changeOperator for updating new operator.
    //@param newOperator address of new owner.
    //@return bool value always true.
    /** restriction: the ADMIN_ROLE address only has the permission to
    updating the new operator.*/
    //@dev see{Accesscontrol}.
    // emits {OperatorUpdated} event.

    function changeOperator(address newOperator)
        external
        onlyRole("ADMIN_ROLE")
        returns (bool)
    {
        require(
            newOperator != address(0),
            "Ownable: new owner is the zero address"
        );
        _revokeRole("OPERATOR_ROLE", operator);
        emit OperatorUpdated(operator, newOperator);
        operator = newOperator;
        _setupRole("OPERATOR_ROLE", newOperator);
        return true;
    }

    //@notice setBaseURI function change the current target ipfs URL to new IPFS target URL.
    //@param _baseTokenURI new IPFS target URL.
    /**
        restriction: the ADMIN_ROLE address only has the permission to change the target ipfs URL.
     */

    function setBaseURI(string memory uri_) external onlyRole("ADMIN_ROLE") returns (bool) {
        emit BaseURIChanged(baseTokenURI, uri_);
        baseTokenURI = uri_;
        return true;
    }

    /**
     * @dev Mints `tokenId` with supply and transfers it to `to`.
     * @dev see{verifySign}.
     * @dev see{ERC1155}.
     * @param _tokenURI ipfs image URI to be get as NFT.
     * @param supply copies to be create.
     * @param _royaltyFee array of royaltyFee permiles.
     * @param _receivers array of royaltyreceivers.
     * @param sign @dev see{Sign}.
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     * - 'nonce' cannot be duplicate value.
     * - versign signer must be match.
     * Emits a {Transfer} event.
     */

    function mint(
        string memory _tokenURI,
        uint256 supply,
        uint96[] calldata _royaltyFee,
        address[] calldata _receivers,
        Sign calldata sign
    ) external virtual returns (uint256 _tokenId) {
        // We cannot just use balanceOf to create the new tokenId because tokens
        // can be burned (destroyed), so we need a separate counter.
        require(!usedNonce[sign.nonce], "Nonce : Invalid Nonce");
        usedNonce[sign.nonce] = true;
        verifySign(_tokenURI, msg.sender, sign);
        _tokenId = _tokenIdTracker.current();
        _mint(_msgSender(), _tokenId, supply, "");
        _tokenURIs[_tokenId] = _tokenURI;
        _setTokenRoyalty(_tokenId, _royaltyFee, _receivers);
        _tokenIdTracker.increment();
        return _tokenId;
    }

    /**
     * @dev Mints `tokenId` with supply to 'from' and transfers qty of NFT to `to`.
     * @dev see{verifySign}.
     * @dev see{ERC1155}.
     * @param _tokenURI ipfs image URI to be get as NFT.
     * @param _royaltyFee array of royaltyFee permiles.
     * @param _receivers array of royaltyreceivers.
     * @param supply copies to be create.
     * @param qty copies to be transfer to 'to'
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     * - 'nonce' cannot be duplicate value.
     *
     * Emits a {Transfer} event.
     */

    function mintAndTransfer(
        address from,
        address to,
        string memory _tokenURI,
        uint96[] calldata _royaltyFee,
        address[] calldata _receivers,
        uint256 supply,
        uint256 qty
    ) external virtual onlyRole("OPERATOR_ROLE") returns(uint256 _tokenId) {
        _tokenId = _tokenIdTracker.current();
        _mint(from, _tokenId, supply, "");
        _tokenURIs[_tokenId] = _tokenURI;
        _setTokenRoyalty(_tokenId, _royaltyFee, _receivers);
        safeTransferFrom(from, to, _tokenId, qty, "");
        _tokenIdTracker.increment();
        return _tokenId;
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     * Restriction
     // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
     */

    function uri(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            exists(tokenId),
            "ERC1155URIStorage: URI query for nonexistent token"
        );

        string memory _tokenURI = _tokenURIs[tokenId];
        // If there is no base URI, return the token URI.
        if (bytes(baseTokenURI).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(baseTokenURI, _tokenURI));
        }
        return
            bytes(baseTokenURI).length > 0
                ? string(abi.encodePacked(baseTokenURI, tokenId.toString()))
                : "";
    }

    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */

    function royaltyInfo(
        uint256 _tokenId,
        uint256 price)
        external
        view
        returns(uint96[] memory, address[] memory, uint256) {
        require(exists(_tokenId),"ERC1155Royalty: query for nonexistent token");
        require(price > 0, "ERC1155Royalty: amount should be greater than zero");
        uint96[] memory royaltyFee = new uint96[](tokenRoyalty[_tokenId].royaltyPermiles.length);
        address[] memory receivers = tokenRoyalty[_tokenId].receivers;
        uint256 royalty;
        uint96[] memory _royaltyFees = tokenRoyalty[_tokenId].royaltyPermiles;
        for( uint96 i = 0; i < _royaltyFees.length; i++) {
            royaltyFee[i] = uint96(price * _royaltyFees[i] / 1000);
            royalty += royaltyFee[i];
        }
        return (royaltyFee, receivers, royalty);
    }

    /**
     * @dev Sets the royalty information for a specific token id.
     *
     * Requirements:
     *
     * - `tokenId` must be already minted.
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */

    function _setTokenRoyalty(
        uint256 _tokenId,
        uint96[] calldata royaltyFeePermiles,
        address[] calldata receivers
    ) internal {
        require(royaltyFeePermiles.length == receivers.length,"ERC1155Royalty: length should be same");
        tokenRoyalty[_tokenId] = TokenRoyalty(royaltyFeePermiles, receivers);
    }

    function isApprovedForAll(address account, address _operator) public view virtual override returns (bool) {
        return (operator == _operator || super.isApprovedForAll(account, _operator));
    }

    //@notice function verifies the singer address from the signed hash.
    //@param _tokenURI IPFS metatdata URI.
    //@param caller address of the caller.
    //@param sign @dev see{Sign}.
    /**
        * Requirements- owner sign verification failed when signture was mismatched.
    */

    function verifySign(
        string memory _tokenURI,
        address caller,
        Sign memory sign
    ) internal view {
        bytes32 hash = keccak256(
            abi.encodePacked(this, caller, _tokenURI, sign.nonce)
        );
        require(
            owner ==
                ecrecover(
                    keccak256(
                        abi.encodePacked(
                            "\x19Ethereum Signed Message:\n32",
                            hash
                        )
                    ),
                    sign.v,
                    sign.r,
                    sign.s
                ),
            "Owner sign verification failed"
        );
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address _operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155Supply, ERC1155) {
        super._beforeTokenTransfer(_operator, from, to, ids, amounts, data);
    }
}