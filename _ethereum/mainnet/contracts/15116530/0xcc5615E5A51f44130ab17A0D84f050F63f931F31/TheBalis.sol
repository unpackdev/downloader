//SPDX-License-Identifier: MIT

/*
                           #####
                       #######
            ######    ########       #####
        ###########/#####\#####  #############
    ############/##########--#####################
  ####         ######################          #####
 ##          ####      ##########/@@              ###
#          ####        ,-.##/`.#\#####               ##
          ###         /  |$/  |,-. ####                 #
         ##           \_,'$\_,'|  \  ###
         #              \_$$$$$`._/   ##
                          $$$$$_/     ##
                          $$$$$        #
                          $$$$$
                          $$$$$
                          $$$$$
                          $$$$$
                         $$$$$
                         $$$$$
                         $$$$$
                         $$$$$        ___
                         $$$$$    _.-'   `-._
                        $$$$$   ,'           `.
                        $$$$$  /               \
~~~~~~~~~~~~~~~~~~~~~~~$$$$$~~~'~~~~~~~~~~~~~~~~`~~~~~~~~~~~~
   ~      ~  ~    ~  ~ $$$$$  ~   ~       ~          ~
       ~ ~      .o,    $$$$$     ~    ~  ~        ~
  ~            ~ ^   ~ $$$$$~        ______    ~        ~
_______________________$$$$$________|\\\\\\\_________________
                       $$$$$        |>\\\\\\\
    ______             $$$$$        |>>\\\\\\\
   \Q%=/\,\            $$$$$       /\>>|#####|
    `------`           $$$$$      /=|\>|#####|
                       $$$$$        ||\|#####|
                      $$$$$$$          ||"""||
                      $$$$$$$          ||   ||
                     $$$$$$$$$
"""""""""""""""""""""$$$$$$$$$"""""""""""""""""""""""""""""""
                        $$$            
*/

pragma solidity ^0.8.0;

import "./ERC2981.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

import "./ERC721A.sol";

contract TheBalis is Ownable, ERC721A, ERC2981, ReentrancyGuard {
    uint96 public ROYALTY_PERCENTAGE = 500;

    uint256 public MAX_FREE_PER_WALLET = 2;
    uint256 public MAX_SUPPLY = 5555;
    uint256 public MAX_TX_PER_WALLET = 4;
    uint256 public SALE_PRICE = 0.002 ether;

    bool public IS_SALE_ACTIVE = false;
    string internal baseURI = "";

    modifier isUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    constructor() ERC721A("TheBalis", "BALIS") {
        _setDefaultRoyalty(owner(), ROYALTY_PERCENTAGE);
    }

    function airdrop(address buyerAddress, uint256 quantity)
        external
        onlyOwner
        nonReentrant
    {
        require(totalSupply() + quantity <= MAX_SUPPLY, "Max supply reached");

        _mint(buyerAddress, quantity);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function mint(uint256 quantity) public payable virtual nonReentrant isUser {
        uint256 salePrice;

        require(IS_SALE_ACTIVE, "Mint not active");

        require(totalSupply() + quantity <= MAX_SUPPLY, "Max supply reached");

        if (_numberMinted(msg.sender) > 0) {
            salePrice = SALE_PRICE * (quantity);
        } else {
            salePrice = SALE_PRICE * (quantity - MAX_FREE_PER_WALLET);
        }

        require(msg.value >= salePrice, "Insufficient funds");

        require(
            _numberMinted(msg.sender) + quantity <= MAX_TX_PER_WALLET,
            "Exceeded tx limit"
        );

        _mint(msg.sender, quantity);
    }

    function getTotalMinted(address addr)
        external
        view
        virtual
        returns (uint256)
    {
        return _numberMinted(addr);
    }

    function setBaseURI(string memory newURI) external virtual onlyOwner {
        baseURI = newURI;
    }

    function setSale(bool isActive) external virtual onlyOwner {
        IS_SALE_ACTIVE = isActive;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId) ||
            super.supportsInterface(interfaceId);
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");

        require(success, "Transfer failed.");
    }
}
