//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./ERC721A.sol";

import "./IERC721.sol";
import "./Address.sol";

contract Wearable is ERC721A, ReentrancyGuard, Ownable {
    using Address for address;
    string public _tokenUriBase;
    State public _state;

    IERC721 private drugReceiptToken;
    IERC721 private seekerToken;

    uint256 public mintingSupply = 359;

    // mint price is 0.08 ether
    uint256 public mintPrice = 0.08 ether;

    mapping(uint256 => mapping(address => bool)) public mintedInBlock;

    event Minted(address indexed minter, uint256 amount);

    enum State {
        DrugReceiptsClaim,
        SeekersClaim,
        Public,
        Closed
    }

    constructor(
        string memory name,
        string memory symbol,
        address _drugReceiptToken,
        address _seekerToken
    ) ERC721A(name, symbol) {
        _state = State.Closed;
        drugReceiptToken = IERC721(_drugReceiptToken);
        seekerToken = IERC721(_seekerToken);
    }

    /* @dev: Setter for minting Supply
     * @param _mintingSupply: uint256
     * @return: void
     */
    function setMintingSupply(uint256 _mintingSupply) external onlyOwner {
        mintingSupply = _mintingSupply;
    }

    /* @dev: Setter for DrupReceipt holders minting stage
     */
    function setDrugReceiptsClaim() external onlyOwner {
        _state = State.DrugReceiptsClaim;
    }

    /* @dev: Setter for Seekers holders minting stage
     */
    function setSeekersClaim() external onlyOwner {
        _state = State.SeekersClaim;
    }

    /* @dev: Setter for Public minting stage
     */
    function setPublic() external onlyOwner {
        _state = State.Public;
    }

    /* @dev: Setter for Closed minting stage
     */
    function setClosed() external onlyOwner {
        _state = State.Closed;
    }

    /* @dev: Setter mint price
     * @param _mintPrice: uint256
     */
    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    /* @dev: Airdrop tokens to the contract
     * @param wallets: address
     */
    function airdrop(address[] calldata wallets) external onlyOwner {
        unchecked {
            for (uint8 i = 0; i < wallets.length; i++) {
                _safeMint(wallets[i], 1);
                emit Minted(wallets[i], 1);
            }
        }
    }

    modifier mintingGuard(uint256 amount) {
        require(msg.sender == tx.origin, "contract not allowed");
        require(!Address.isContract(msg.sender), "contract not allowed");
        require(msg.value >= amount * mintPrice, "invalid amount");
        require(amount > 0, "You must mint at least 1 token");
        require(amount < 6, "You can't claim more than 5 tokens at a time");
        require(
            totalSupply() + amount <= mintingSupply,
            "claim has reached max supply"
        );
        _;
    }

    /* @dev: DrugReceipt holders minting stage
     * @param amount: uint256
     */
    function mintDrugReceiptsClaim(uint256 amount)
        external
        payable
        nonReentrant
        mintingGuard(amount)
    {
        require(
            _state == State.DrugReceiptsClaim,
            "Claim is not available at this time"
        );
        require(
            drugReceiptToken.balanceOf(msg.sender) > 0,
            "You don't have any drug receipts"
        );

        require(
            mintedInBlock[block.number][msg.sender] == false,
            "already minted in block"
        );
        mintedInBlock[block.number][msg.sender] = true;

        _safeMint(msg.sender, amount);
    }

    /* @dev: Seeker holders minting stage
     * @param amount: uint256
     */
    function mintSeekersClaim(uint256 amount)
        external
        payable
        nonReentrant
        mintingGuard(amount)
    {
        require(
            _state == State.SeekersClaim,
            "Claim is not available at this time"
        );
        require(
            seekerToken.balanceOf(msg.sender) > 0 ||
                drugReceiptToken.balanceOf(msg.sender) > 0,
            "You don't have any Seekers or DrugReceipts"
        );

        require(
            mintedInBlock[block.number][msg.sender] == false,
            "already minted in block"
        );
        mintedInBlock[block.number][msg.sender] = true;

        _safeMint(msg.sender, amount);
    }

    /* @dev: Public minting stage
     * @param amount: uint256
     */
    function mintPublic(uint16 amount)
        external
        payable
        nonReentrant
        mintingGuard(amount)
    {
        require(_state == State.Public, "Claim has not started yet");
        require(
            mintedInBlock[block.number][msg.sender] == false,
            "already minted in block"
        );
        mintedInBlock[block.number][msg.sender] = true;

        _safeMint(msg.sender, amount);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        return
            string(abi.encodePacked(_tokenUriBase, Strings.toString(tokenId)));
    }

    function setTokenURI(string memory tokenUriBase_) public onlyOwner {
        _tokenUriBase = tokenUriBase_;
    }

    /* @dev: Withdraw all ETH to a given address
     * @param recipient: address
     */
    function withdrawAll(address recipient) public onlyOwner {
        uint256 balance = address(this).balance;
        payable(recipient).transfer(balance);
    }

    function withdrawAllViaCall(address payable _to) public onlyOwner {
        uint256 balance = address(this).balance;
        (bool sent, bytes memory data) = _to.call{value: balance}("");
        require(sent, "Failed to send Ether");
    }
}
