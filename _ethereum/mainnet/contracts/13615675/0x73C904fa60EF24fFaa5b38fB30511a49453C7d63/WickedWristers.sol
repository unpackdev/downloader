// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";
import "./ERC165.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./Address.sol";
import "./Context.sol";
import "./Strings.sol";
import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC721Enumerable.sol";
import "./ERC721Enumerable.sol";

contract WickedWristers is ERC721Enumerable, Ownable {
    
    using SafeMath for uint256;

    string public WRISTERS_PROVENANCE = ""; 

    uint256 public constant wristerPrice = 80000000000000000;           // 0.08 ETH

    uint256 public MAX_WRISTERS_PRESALE = 232;                          // max wristers possible for presale

    uint256 public MAX_WRISTERS = 800;                                  // max wristers possible to start sim

    uint256 public MAX_WRISTERS_ADMIN = 22;                             // max wristers admin mintable 

    bool public publicSaleIsActive = false;                             // public sale active toggle 

    bool public preSaleIsActive = false;                                // pre sale active toggle 

    bool public adminSaleIsActive = false;                              // admin sale active toggle

    uint256 public maxWristersMintable  = 2;                            // max wristers allowed to be mint per wallet

    uint256 public constant maxAdminMintable = 10;                      // max wristers allowed to be mint per wallet during admin mint

    string _baseTokenURI;

    address t1 = 0x1ec4D5B1A1aC80a0fd1559afF69F4aB5200d20F0; // jayareuu
    address t2 = 0x978549262a2E86a7Dc7e7bad660f521162f06d09; // gurgleswamp
    address t3 = 0x09d6bb3a5CC7E943907D002e1BCc834A2Af381c2; // wolvesatmydoor
    address t4 = 0xe96181c6744e0f53271Ed4419f40217C59523A61; // bdubs
    address t5 = 0x7914559444945712F803543Ec8986494bB7fDb5C; // decoy
    address t6 = 0xa9C7168dD72996D4d4353E384127b59Dbf95117A; // wicked wristers


    event Active(bool saleIsActive);

    mapping(address => bool) private _adminEligible;
    mapping(address => bool) private _presaleEligible;
    mapping(address => uint256) private _totalClaimed;

    constructor() ERC721("Wicked Wristers", "WW") {
    }

    function withdrawAll() public onlyOwner {
        uint256 _jayareuu = address(this).balance * 150/1000;
        uint256 _gurgleswamp = address(this).balance * 150/1000;
        uint256 _wolvesatmydoor = address(this).balance * 350/1000;
        uint256 _bdubs = address(this).balance * 75/1000;
        uint256 _decoy = address(this).balance * 75/1000;
        uint256 _Wicked_Wristers = address(this).balance * 200/1000;
        require(payable(t1).send(_jayareuu));
        require(payable(t2).send(_gurgleswamp));
        require(payable(t3).send(_wolvesatmydoor));
        require(payable(t4).send(_bdubs));
        require(payable(t5).send(_decoy));
        require(payable(t6).send(_Wicked_Wristers));
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        WRISTERS_PROVENANCE = provenanceHash;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function addToPresale(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Cannot add null address");

            _presaleEligible[addresses[i]] = true;

            _totalClaimed[addresses[i]] > 0 ? _totalClaimed[addresses[i]] : 0;
        }
    }

    function addToAdmin(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Cannot add null address");

            _adminEligible[addresses[i]] = true;

            _totalClaimed[addresses[i]] > 0 ? _totalClaimed[addresses[i]] : 0;
        }
    }

    function checkPresaleEligiblity(address addr) external view returns (bool) {
        return _presaleEligible[addr];
    }

    function checkAdminEligiblity(address addr) external view returns (bool) {
        return _adminEligible[addr];
    }

    function flipSaleState() public onlyOwner {
        publicSaleIsActive = !publicSaleIsActive;
        emit Active(publicSaleIsActive);
    }

    function flipPreSaleState() public onlyOwner {
        preSaleIsActive = !preSaleIsActive;
        emit Active(preSaleIsActive);
    }

    function flipAdminSaleState() public onlyOwner {
        adminSaleIsActive = !adminSaleIsActive;
        emit Active(adminSaleIsActive);
    }

    function setPostSeasonMaxWristers(uint256 newMAX_WRISTERS) public onlyOwner{
        MAX_WRISTERS = newMAX_WRISTERS;
    }

    function setmaxWristersMintablePerWallet(uint256 newmaxWristersMintable) public onlyOwner{
        maxWristersMintable = newmaxWristersMintable;
    }

    function mintPresale(uint256 numberOfTokens) public payable {
        require(totalSupply() < MAX_WRISTERS_PRESALE, "All tokens have been minted for presale");
        require(preSaleIsActive, "Pre sale must be active to mint Wrister");
        require(_presaleEligible[msg.sender], "You are not eligible for the presale buddy");
        require(_totalClaimed[msg.sender].add(numberOfTokens) <= maxWristersMintable, "Purchase exceeds max allowed per wallet of 2");
        require(numberOfTokens > 0, "Must mint at least one Wrister");
        require(msg.value >= wristerPrice.mul(numberOfTokens), "Ether value sent is not correct");

        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < MAX_WRISTERS_PRESALE) {
                _totalClaimed[msg.sender] += 1;
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    function mintWrister(uint numberOfTokens) public payable {
        require(totalSupply() < MAX_WRISTERS, "All tokens have been minted for this season");
        require(publicSaleIsActive, "Public sale must be active to mint Wrister");
        require(_totalClaimed[msg.sender].add(numberOfTokens)  <= maxWristersMintable, "Purchase exceeds max allowed per wallet of 2");
        require(numberOfTokens > 0, "Must mint at least one Wrister");
        require(msg.value >= wristerPrice.mul(numberOfTokens), "Ether value sent is not correct");

        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < MAX_WRISTERS) {
                _totalClaimed[msg.sender] += 1;
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    function mintAdmin(uint numberOfTokens) public {
        require(totalSupply() < MAX_WRISTERS_ADMIN, "All tokens have been minted for the admin sale");
        require(_adminEligible[msg.sender], "You are not eligible for the admin buddy");
        require(adminSaleIsActive, "Admin sale must be active to mint Wrister");
        require(_totalClaimed[msg.sender].add(numberOfTokens)  <= maxAdminMintable, "Purchase exceeds max allowed per wallet of 10");
        require(numberOfTokens > 0, "Must mint at least one Wrister");

        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < MAX_WRISTERS_ADMIN) {
                _totalClaimed[msg.sender] += 1;
                _safeMint(msg.sender, mintIndex);
            }
        }
    }
}




