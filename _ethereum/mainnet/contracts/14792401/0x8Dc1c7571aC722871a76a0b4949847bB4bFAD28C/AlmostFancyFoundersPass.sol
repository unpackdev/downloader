// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721AQueryable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./MerkleMintable.sol";

// @author erosemberg from almostfancy.com
contract AlmostFancyFoundersPass is
    ERC721AQueryable,
    Ownable,
    ReentrancyGuard,
    MerkleMintable
{
    uint256 public immutable mintPrice = 0.033 ether;
    uint256 public constant MAX_SUPPLY = 1111;

    enum SaleState {
        CLOSED,
        ALMOST_LIST,
        PUBLIC
    }
    SaleState public saleState;

    bool public reserveMinted = false;

    string private baseURI;
    string private baseURIConsumed;

    mapping(uint256 => bool) private usedPasses;
    address private almostFancy;

    // solhint-disable-next-line
    constructor() ERC721A("Almost Fancy Founders Pass", "AFFP") {}

    modifier requireState(SaleState state) {
        require(saleState == state, "AlmostFancy: Sale is not active");
        _;
    }

    modifier callerIsReal() {
        require(
            // solhint-disable-next-line avoid-tx-origin
            tx.origin == msg.sender,
            "AlmostFancy: We only like real users!"
        );
        _;
    }

    modifier callerIsAF() {
        require(
            msg.sender == almostFancy,
            "AlmostFancy: Caller can only be AlmostFancy"
        );
        _;
    }

    function mintAlmostList(bytes32[] memory proof)
        external
        payable
        requireState(SaleState.ALMOST_LIST)
        isAbleToMint(msg.sender, proof)
        canMint(msg.sender, 1, 1)
    {
        _doMint(msg.sender);
        _merkleMint(msg.sender, 1);
    }

    function mintPublic() external payable requireState(SaleState.PUBLIC) {
        _doMint(msg.sender);
    }

    function _doMint(address minter) internal {
        require(
            totalSupply() + 1 <= MAX_SUPPLY,
            "AlmostFancy: Almost Fancy Founders Passes have sold out!"
        );
        require(
            balanceOf(minter) == 0,
            "AlmostFancy: You already own an Almost Fancy founders pass!"
        );

        _safeMint(minter, 1);
        refundIfOver(mintPrice);
    }

    // BEGIN: section for external (AF) functions
    function consumePass(uint256 pass) external callerIsAF {
        require(
            !usedPasses[pass],
            "AlmostFancy: This pass has already been used!"
        );
        usedPasses[pass] = true;
    }

    function isPassConsumed(uint256 pass) external view returns (bool) {
        return usedPasses[pass];
    }

    function ownsPass(address owner, uint256 passId)
        external
        view
        returns (bool)
    {
        return ownerOf(passId) == owner;
    }

    // END: section for external (AF) functions

    // BEGIN: section admin functions
    function withdrawAll() external onlyOwner nonReentrant {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function setAlmostFancy(address _almostFancy) external onlyOwner {
        almostFancy = _almostFancy;
    }

    function reserveTokens(uint256 quantity)
        external
        onlyOwner
        requireState(SaleState.CLOSED)
    {
        require(
            !reserveMinted,
            "AlmostFancy: Reserve tokens have already been minted"
        );

        _safeMint(msg.sender, quantity);
        reserveMinted = true;
    }

    function forceDeconsumption(uint256 passId) external onlyOwner {
        usedPasses[passId] = false;
    }

    function setSaleState(SaleState state) external onlyOwner {
        saleState = state;
    }

    function setBaseUris(string memory uri, string memory uriConsumed)
        external
        onlyOwner
    {
        baseURI = uri;
        baseURIConsumed = uriConsumed;
    }

    function setMerkle(bytes32 root) external onlyOwner {
        _setMerkleRoot(root);
    }

    // END: section admin functions

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (usedPasses[tokenId]) {
            return
                string(
                    abi.encodePacked(baseURIConsumed, Strings.toString(tokenId))
                );
        }
        return super.tokenURI(tokenId);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function refundIfOver(uint256 cost) internal {
        require(msg.value >= cost, "AlmostFancy: ETH value sent was too low");
        if (msg.value > cost) {
            payable(msg.sender).transfer(msg.value - cost);
        }
    }
}
