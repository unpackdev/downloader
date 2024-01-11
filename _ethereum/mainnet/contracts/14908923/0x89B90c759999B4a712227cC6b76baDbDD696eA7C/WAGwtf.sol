// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./ERC721A.sol";
import "./Ownable.sol";

//                                                                              mmmm
// *@@@@*     @     *@@@*      @@        mm@***@m@                     @@     m@* **
//   *@@     m@@     m@       m@@m     m@@*     *@                     @@     @@*   
//    @@m   m@@@m   m@       m@*@@!    @@*       * *@@*    m@    *@@*@@@@@@  @@@@@  
//     @@m  @* @@m  @*      m@  *@@    @!            @@   m@@@   m@    @@     @@    
//     !@@ @*  *@@ @*       @@@!@!@@   @!m    *@@@@   @@ m@  @@ m@     @@     !@    
//      !@@m    !@@m       !*      @@  *!@m     @@     @@@    @!!      @!     !@    
//      !!@!*   !!@!*       !!!!@!!@   !!!    *!@!!    !@!!   !:!      !!     !:    
//      !!!!    !!!!       !*      !!  *:!!     !!     !!!    !:!      !!     !:    
//       :       :       : : :   : :::   ::: : ::       :      :       ::: :: :::   
//
                                                                                 
contract WAGwtf is Ownable, ERC721A {
    uint256 public immutable maxSupply          = 5000;
    uint256 public maxPerTxDuringMint           = 5;
    uint256 public maxPerAddressDuringMint      = 20;
    bool    public saleIsActive                 = false;

    string private _baseTokenURI;

    mapping(address => uint256) public mintedAmount;

    constructor() ERC721A("We are all going to ...", "WAGwtf") {}

    modifier mintCompliance() {
        require(saleIsActive, "Sale is not active yet.");
        require(tx.origin == msg.sender, "Caller cannot be a contract.");
        _;
    }

    function mint(uint256 _quantity) external mintCompliance() {
        require(
            maxSupply >= totalSupply() + _quantity,
            "WAGwtf: Exceeds max supply."
        );
        uint256 _mintedAmount = mintedAmount[msg.sender];
        require(
            _mintedAmount + _quantity <= maxPerAddressDuringMint,
            "WAGwtf: Exceeds max mints per address!"
        );
        require(
            _quantity > 0 && _quantity <= maxPerTxDuringMint,
            "Invalid mint amount."
        );
        mintedAmount[msg.sender] = _mintedAmount + _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function devMint(address _receiver, uint256 _quantity) external onlyOwner {
	    require(
            maxSupply >= totalSupply() + _quantity,
            "Cannot reserve more than max supply"
        );
        _safeMint(_receiver, _quantity);
    }

    function setMaxPerTx(uint256 _amount) external onlyOwner {
        maxPerTxDuringMint = _amount;
    }

    function setMaxPerAddress(uint256 _amount) external onlyOwner {
        maxPerAddressDuringMint = _amount;
    }

    function flipSale() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function withdrawBalance() external onlyOwner {
		(bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Withdraw failed.");
	}
}