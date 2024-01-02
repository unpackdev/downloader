// SPDX-License-Identifier: MIT
/*
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::-%@@+:::::::=@@+:::::::-%=:::::::::::::::::::::::::
::::::::::::::::::-%#+#@-:::=@#++#@-::::*@#@:::::::::::::::::::::::::
::::::::::::::::::-%#+++@%:#@+++++#@-:-@%++@=::::::::::::::::::::::::
::::::::::::::::::-%#++++#@%+++++++*@@@#+++#%::::::::::::::::::::::::
:::::::::::::::::::#%++++++++++++++++++++++*@=:::::::::::::::::::::::
::::::::::::::::::::@#+++++++++++++++++++++*@=:::::::::::::::::::::::
::::::::::::::::::::-@%++++++++++++++++++++@#::::::::::::::::::::::::
::::::::::::::::::::::-#@@@%###%*++++++++%@+:::::::::::::::::::::::::
::::::::::::::::::::::::::::::-@+=+%%%*=--:::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::@=::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::-::@=::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::#%*@@--**-::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::-@*=@@@*%%-:::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::*@@#*#@-::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::#@@#-:::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::*#::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::*#::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::-@:::::::::::::-::::::::::::::::::::::
:::::::::::::::::::+@@#::::::::-@@-:::::::::+@*@*::::::::::::::::::::
::::::::::::::::::-%#+#@=::::::*@#@-:::::::=@-::+@-::::::::::::::::::
::::::::::::::::::=@+++*@+::::-@##%%::::::-@-::::=%::::::::::::::::::
::::::::::::::::::%#+++++@=:::*@###@%-::::+%::::::#%-::::::::::::::::
:::::::::::::::::*@+++++++@+:=@######@=::=@::::::::-@=:::::::::::::::
:::::::::::::::::@+++++++++@@@########@=+@-::::::::::@+::::::::::::::
:::::::::::::::-@%%%%%%%%%%%@@%%%%%%%%%@@%************@#:::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
*/

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";



contract SuoloRose is  ERC721A, Ownable {
    using Address for address;

    //#USUAL FARE
    string public baseURI;
    uint256 public roseSupply = 100;
    uint256 public allowlistMintAmount = 1;

    bytes32 public merkleroot = 0xbaa07b2bced28e157733470b15a25233f05393cb6c0c7460daa40eaa470f468d;

    mapping(address => uint256) private mintCount;


    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    constructor() ERC721A("SuoloRose", "ROSE") {
    }

    function isAllowlisted(address _address, bytes32[] calldata _merkleProof) public view returns (bool){
                
        bytes32 leaf = keccak256(abi.encodePacked(_address));

        bool res = MerkleProof.verify(_merkleProof,merkleroot,leaf);

        return res;
    }

    function allowListMint(bytes32[] calldata _merkleProof) external payable {
        address _to = msg.sender;
        
        uint256 minted = mintCount[_to];

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        require(MerkleProof.verify(_merkleProof,merkleroot,leaf), "Invalid Proof.");
        require(msg.sender == tx.origin,"message being sent doesn't not match origin");

        require(minted + 1 <= allowlistMintAmount, "mint over max");
        require(totalSupply() + 1 <= roseSupply, "mint over supply");

        mintCount[_to] = minted + 1;
        _mint(msg.sender, 1);
    }

    // Only Owner executable functions
    function mintByOwner(address _to, uint256 _mintAmount) external onlyOwner {
        require(totalSupply() + _mintAmount <= roseSupply, "mint over supply");
        _mint(_to, _mintAmount);

    }

    
    //#SETTERS
    function setBaseURI(string memory _newURI) external onlyOwner {
        baseURI = _newURI;
    }


    function updateMerkle(bytes32 _merkleRoot) external onlyOwner{
        merkleroot = _merkleRoot;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }  



}