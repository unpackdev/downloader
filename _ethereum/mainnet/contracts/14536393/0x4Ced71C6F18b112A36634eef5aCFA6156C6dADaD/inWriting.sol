//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT

//               ____ ____ _________ ____ ____ ____ ____ ____ ____ ____ 
//              ||I |||n |||       |||W |||r |||i |||t |||i |||n |||g ||
//              ||__|||__|||_______|||__|||__|||__|||__|||__|||__|||__||
//              |/__\|/__\|/_______\|/__\|/__\|/__\|/__\|/__\|/__\|/__\|


pragma solidity ^0.8.1;

import "./ERC721.sol";  // implementation of the erc721 standard, string nft inherits from this
import "./Counters.sol";  // counters that can only be incremented or decremented by 1
import "./Ownable.sol";  // sets up access control so that only the owner can interact
import "./base64.sol";  // gets enoding functions
//import "./strings.sol";

contract ERC721 is Context, ERC165, IERC721, IERC721Metadata, Ownable{
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        require(forSale[tokenId] == 0, "This token is up for sale, it must be de-listed before it can burned");
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        require(forSale[tokenId] == 0, "This token is up for sale, it must be de-listed before it can approve an address");
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}


    // ------------------------------------
    // implement buy and sell functionality
    // ------------------------------------

    mapping(uint256 => uint256) private forSale;  // initialize mapping of token ID to sale price

    event Listed(uint256 tokenId, uint256 price);  // event for when a token is listed for sale
    event Bought(uint256 tokenId, uint256 price);  // event for when a token is bought

    uint256 fee = 0;  // platform fee for purchasing on platform -- can be changed by platform owners

    /**
     * @dev Adds a token to the forSale mapping
     *
     * Requirements:
     *
     * - `price` must be greater than 0.
     * - msg.sender is the owner of the token.
     *
     * Emits a {Listed} event.
     */
    function list_for_sale(uint256 tokenId, uint256 price) public returns (bool) {
        require(price != 0, "price must be greater than zero");
        require(msg.sender == ownerOf(tokenId), "you are not the owner of this token, you can not sell it");

        approve(address(0), tokenId);
        forSale[tokenId] = price;

        emit Listed(tokenId, price);

        return true;
    }

    /**
     * @dev Removes token from the forSale mapping
     *
     * Requirements:
     *
     * - `tokenId` must be for sale (in `forSale` mapping).
     * - msg.sender is the owner of the token.
     *
     * Emits a {Bought} event.
     *   - Bought events with price = 0 are counted as `delisted`
     */
    function delist_for_sale(uint256 tokenId) public returns (bool) {
        require(forSale[tokenId] != 0, "token not for sale");
        require(msg.sender == ownerOf(tokenId), "you are not the owner of this token, so you cannot de-list it");

        delete forSale[tokenId];

        emit Bought(tokenId, 0);

        return true;
    }

    /**
     * @dev Returns the price (plus a fee) for the token in the forSale mapping
     *
     * Requirements:
     *
     * - `tokenId` must be for sale (in `forSale` mapping).
     *
     */
    function get_price(uint256 tokenId) public view returns (uint256) {
        require(forSale[tokenId] != 0, "token not for sale");
        return forSale[tokenId] + fee;
    }

    function is_token_for_sale(uint256 tokenId) internal view returns (bool) {
        return forSale[tokenId] != 0;
    }

    /**
     * @dev Returns the fee of buying a token on the marketplace
     *
     */
    function get_buying_cost() public view returns (uint256) {
        return fee;
    }

    /**
     * @dev Allows user to purchase a token from a buyer.
     *  transfers token from seller to buyer
     *  transfers funds from buyer to seller, deducts platform fee if enabled
     *
     * Requirements:
     *
     * - `tokenId` must be for sale (in `forSale` mapping).
     * - msg.value must be greater than or equal to the sale price (forSale[tokenId]).
     *
     * Emits a {Bought} event.
     */
    function buy(uint256 tokenId) public payable returns (bool) {
        require(forSale[tokenId] != 0, "token not for sale");
        uint256 value = msg.value - fee;
        require(value >= forSale[tokenId], "insufficient value");

        address seller = ownerOf(tokenId);
        uint256 price = forSale[tokenId];

        delete forSale[tokenId];

        _transfer(seller, msg.sender, tokenId);
        //(bool sent, ) = payable(seller).call{value: price}("");
        //require(sent, "transaction failed");
        payable(seller).transfer(price);

        if (msg.value > price) {
            //(sent, ) = msg.sender.call{value: value - price}("");
            //require(sent, "refund failed");
            payable(msg.sender).transfer(value - price);
        }

        emit Bought(tokenId, price);

        return true;
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - `tokenId` token must not be up for sale. 
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");
        require(forSale[tokenId] == 0, "This token is up for sale, it must be de-listed before it can be transferred");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    // contract owner can set and change a fee for purchasing an nft on platform
    function update_buying_cost(uint256 newFee) public onlyOwner {
        fee = newFee;
    }
}

// start contract code

contract InWriting is ERC721{
    using Counters for Counters.Counter;  // set counter object path
    Counters.Counter private _tokenIds;  // initialize counter object
    using Strings for uint256;
    mapping(string => bool) private usedStrings;  // initialize mapping for keeping track of unique strings
    mapping(uint256 => string) private tokenIDtoString;  // initialize mapping of token ID to string
    mapping(uint256 => bool) private unlocked;  // initialize mapping of locked stated of tokens
    uint256 cost = 0;  // set the minting fee to 0

    event Appended(uint256 tokenId, address addr);  // event for when a token appended to

    constructor() ERC721("InWriting", "WRITE") {}  // smart contract's name, smart contract's symbol

    // image variables
    string image_url = 'https://inwritingapi.com/inwriting/get_svg.php?tokenID=';

    // change image url after deployment if needed
    function change_image_url(string memory str) public onlyOwner {
        image_url = str;
    }

    // checks to see if a string has been minted already
    function check_if_used(string memory str) public view returns (bool) {  // view means that we can look at the value of a state variable in the contract
        return usedStrings[str];  // tell us if the string is in the mapping (true if there, false if not)
    }

    // given tokenId, returns the string associated with that token
    function get_string(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "TokenID does not exist!");  // make sure the tokenID is valid
        return tokenIDtoString[tokenId];  // get the string from the mapping
    }

    string description = "";

    // change description after deployment if needed
    function change_description(string memory desc) public onlyOwner {
        description = desc;
    }

    string external_url = "https://inwriting.io/text.html?tokenID=";

    // change external url after deployment if needed
    function change_external_url(string memory url) public onlyOwner {
        external_url = url;
    }

    // override the default function and wrap the string in a nice little base64'd json format
    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        string memory base = 'data:application/json;base64,';  // base string telling the browser the json is in base64
        string memory tokenID = tokenId.toString();
        string memory json = string(abi.encodePacked(
            '{\n\t"name": "In Writing #', tokenID, 
            '",\n\t"string": "', Base64.encode(bytes(get_string(tokenId))),  // base64 encoded so it doesn't break the json
            '",\n\t"external_url": "', external_url, tokenID,
            '",\n\t"description": "', description,
            '",\n\t"tokenId": "', tokenID,
            '",\n\t"image_data": "', string(abi.encodePacked(image_url, tokenID)), '"\n}'));  // format the json

        return string(abi.encodePacked(base, Base64.encode(bytes(json))));  // return the full concatenated string
    }

    // owner can withdraw from the contract address
    function withdraw(uint256 amt) public onlyOwner {
        require(amt <= address(this).balance);
        payable(owner()).transfer(amt);
    }

    // owner can change the minting cost
    function update_minting_cost(uint256 newCost) public onlyOwner {
        cost = newCost;
    }

    // returns the cost (gas excluded) of minting a string in wei
    function get_minting_cost() public view returns (uint256) {
        return cost;
    }

    // mint the token
    function mint_NFT(string memory str) public payable returns (uint256) {
        require(msg.value >= cost, "payment not sufficient");  // msg.value must be larger than the minting fee
        require(!usedStrings[str], "this string has already been minted");  // check to make sure the string is unique

        uint256 newItemId = _tokenIds.current();  // get the current itemID
        _tokenIds.increment();  // increment the tokenID

        tokenIDtoString[newItemId] = str;  // update the mapping
        string storage str_at_pointer = tokenIDtoString[newItemId];  // get pointer for the string so we don't write twice
        usedStrings[str_at_pointer] = true;  // overwrite mapping, this time with the storage pointer string for efficiency
        
        _mint(msg.sender, newItemId);  // mint the nft and send it to the person who called the contract

        if (msg.value > cost) {
            payable(msg.sender).transfer(msg.value - cost);
        }

        return newItemId;
    }

    // mint a token and immediately list it for sale
    function mint_and_list_NFT(string memory str, uint256 price) public payable returns (uint256) {
        uint256 tokenId = mint_NFT(str);
        list_for_sale(tokenId, price);
        return tokenId;
    }

    // mint a token in the unlocked state so that more characters can be added to it
    function mint_unlocked_NFT(string memory str) public payable returns (uint256) {
        uint256 tokenId =  mint_NFT(str);
        unlocked[tokenId] = true;
        return tokenId;
    }

    // mint an unlocked token and immediately list it for sale
    function mint_and_list_unlocked_NFT(string memory str, uint256 price) public payable returns (uint256) {
        uint256 tokenId = mint_unlocked_NFT(str);
        list_for_sale(tokenId, price);
        return tokenId;
    }

    // add more charcters to the token
    function append_to_NFT(uint256 tokenId, string memory str) public {
        require(msg.sender == ownerOf(tokenId), "you are not the owner of this token, so you cannot append to it");
        require(unlocked[tokenId], "this token is locked, so it may not be modified");
        require(!is_token_for_sale(tokenId), "this token is up for sale, so it cannot be appened to");
        string memory oldString = tokenIDtoString[tokenId];
        string memory newString = string(abi.encodePacked(oldString, str));
        require(!usedStrings[newString], "this string has already been minted");  // check to make sure the string is unique
        
        tokenIDtoString[tokenId] = newString;
        string storage newString_ = tokenIDtoString[tokenId];
        usedStrings[newString_] = true;

        delete usedStrings[oldString];

        emit Appended(tokenId, msg.sender);
    }

    // lock the token so it can no longer be modified
    function lock_NFT(uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "you are not the owner of this token");
        delete unlocked[tokenId];
    }

    // return the total number of In Writing NFTs that exist
    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }

}