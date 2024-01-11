// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC2981.sol";
import "./Address.sol";

//     __      _                ______      __
//    / /_  __(_)___  ____ _   / __/ /___ _/ /_
//   / / / / / / __ \/ __ `/  / /_/ / __ `/ __/
//  / / /_/ / / / / / /_/ /  / __/ / /_/ / /_
// /_/\__, /_/_/ /_/\__, /  /_/ /_/\__,_/\__/
//   /____/        /____/

contract LayingFlat is ERC721, IERC2981, ReentrancyGuard, Ownable {
    constructor(string memory customBaseURI_) ERC721("Laying Flat", "FLAT") {
        customBaseURI = customBaseURI_;
    }

    /** MINTING **/

    uint256 public constant MINT_LIMIT_PER_WALLET = 2;
    uint256 public constant MAX_SUPPLY = 20;
    uint256 public constant PRICE = 0.1 ether;
    uint16 private mintCounter = 1;
    bool public isPublicSaleActive;

    //** EVENTS */

    modifier publicSaleActive() {
        require(isPublicSaleActive, "Public sale is not open");
        _;
    }

    event MintedAnNFT(address indexed to, uint256 indexed tokenId);

    function mint(uint256 count) public payable nonReentrant publicSaleActive {
        require(
            balanceOf(msg.sender) + count <= MINT_LIMIT_PER_WALLET,
            "Minting limit exceeded"
        );
        require(mintCounter + count - 1 <= MAX_SUPPLY, "Exceeds max supply");
        require(
            msg.value >= PRICE * count,
            "Insufficient payment, 0.1 ETH per item"
        );

        for (uint256 i = 0; i < count; i++) {
            _mint(msg.sender, mintCounter);
            emit MintedAnNFT(msg.sender, mintCounter);
            unchecked {
                mintCounter++;
            }
        }
    }

    /** URI HANDLING **/

    string private customContractURI =
        "ipfs://bafybeiddblti7v4kmhda2neoggpr3jaikdz5rbp4xzzqqyjykotkmf45xy/";

    function setContractURI(string memory customContractURI_)
        external
        onlyOwner
    {
        customContractURI = customContractURI_;
    }

    function contractURI() public view returns (string memory) {
        return customContractURI;
    }

    string private customBaseURI;

    function setBaseURI(string memory customBaseURI_) external onlyOwner {
        customBaseURI = customBaseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return customBaseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return string(abi.encodePacked(super.tokenURI(tokenId), ".token.json"));
    }

    /** PAYOUT **/

    address private constant payoutAddress1 =
        0x52aA63A67b15e3C2F201c9422cAC1e81bD6ea847;
    address private constant payoutAddress2 =
        0xc178ED301ADF2B73609B6d527386f21618c323c2;

    function withdraw() public nonReentrant onlyOwner {
        uint256 balance = address(this).balance;

        Address.sendValue(payable(payoutAddress1), (balance * 50) / 100);

        Address.sendValue(payable(payoutAddress2), (balance * 50) / 100);
    }

    /** ROYALTIES **/

    function royaltyInfo(uint256, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (address(this), (salePrice * 1500) / 10000);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, IERC165)
        returns (bool)
    {
        return (interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId));
    }

    //** ACTIVATE PUBLIC SALE **/
    function setIsPublicSaleActive(bool _isPublicSaleActive)
        external
        onlyOwner
    {
        isPublicSaleActive = _isPublicSaleActive;
    }
}
