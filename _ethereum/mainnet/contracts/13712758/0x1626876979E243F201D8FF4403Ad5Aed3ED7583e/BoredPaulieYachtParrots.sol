//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./PaymentSplitter.sol";
import "./Pausable.sol";
import "./IERC721.sol";
import "./ERC721Enumerable.sol";
import "./Address.sol";
import "./Strings.sol";

//🎩🐭 fancyrats.eth

contract BoredPaulieYachtParrots is
    ERC721Enumerable,
    Ownable,
    Pausable,
    PaymentSplitter
{
    using Address for address;
    using Strings for uint256;

    uint256 public mintPrice = 0.0420 ether;

    uint256 private constant BAYC_SUPPLY = 10000;

    string private baseURI;

    IERC721 private immutable bayc;

    constructor(
        address _baycAddress,
        string memory baseURI_,
        address[] memory payees,
        uint256[] memory shares_
    )
        ERC721("BORED PAULIE: YACHT PARROTS", "BP:YP")
        Pausable()
        Ownable()
        PaymentSplitter(payees, shares_)
    {
        baseURI = baseURI_;
        bayc = IERC721(_baycAddress);
        _pause();
    }

    function pauseSale() public onlyOwner {
        _pause();
    }

    function startSale() public onlyOwner {
        _unpause();
    }

    function claim(uint256 _baycTokenId)
        public
        payable
        isValidPayment
        ownsBAYCToken(_baycTokenId)
        whenNotPaused
    {
        _claim(msg.sender, _baycTokenId);
    }

    // @notice To only be used after BAYC claim window
    function mintUnclaimed(uint256 _baycTokenId) public onlyOwner {
        _claim(msg.sender, _baycTokenId);
    }

    function _claim(address to, uint256 _baycTokenId) private {
        // Token supply is gated by BAYC,
        require(_baycTokenId < BAYC_SUPPLY, "There are only 10,000 apes tho");
        _safeMint(to, _baycTokenId);
    }

    function setClaimPrice(uint256 _newMintPrice) public onlyOwner {
        mintPrice = _newMintPrice;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

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
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    modifier ownsBAYCToken(uint256 _baycTokenId) {
        require(
            bayc.ownerOf(_baycTokenId) == msg.sender,
            "Must own BAYC token"
        );
        _;
    }

    modifier isValidPayment() {
        require(msg.value == mintPrice, "Invalid Ether amount sent");
        _;
    }
}
