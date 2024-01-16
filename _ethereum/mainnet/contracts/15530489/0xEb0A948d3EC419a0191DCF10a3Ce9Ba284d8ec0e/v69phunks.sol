// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC721R.sol";
import "./Ownable.sol";
interface ICM {
    function balanceOf(address owner) external view returns (uint256); 
}
interface IV3 {
    function balanceOf(address owner) external view returns (uint256);
}
contract v69Phunks is ERC721r, Ownable {
    mapping(address => bool) public isAList;
    mapping(address => uint256) public walletMinted;
    uint8 public maxPhreePerWallet = 1;
    uint8 public Phree = 0.0 ether;
    uint16 public maxPhree = 690;
    uint16 public maxWifeys = 6969;
    uint256 public mintedWifeys;    
    uint256 public phreeWifeyMints = 0;
    uint256 public mintPrice = 0.0069 ether;
    bool public aListMintOn = false;
    bool public publicMintOn = false;
    bool mintSuccess;
    address public CMaddy = 0xe9b91d537c3Aa5A3fA87275FBD2e4feAAED69Bd0;
    address public v3addy  = 0xb7D405BEE01C70A9577316C1B9C2505F146e8842;

    constructor() ERC721r("v69 Phunks", "Wifeys", 6_969) {}
        modifier whenMintActive() {
            require(aListMintOn || publicMintOn, "Mint is not active");
            _;
        }
        function toggleAListMint() public onlyOwner {
            aListMintOn = !aListMintOn;
        } 
        //end alist mint and start publicmint
        function togglePublicMint() public onlyOwner{
            aListMintOn = false;
            publicMintOn = !publicMintOn;
        }
        function checkAList() public view returns(bool) {
            return isAList[msg.sender];
        }
        function aListSelf() public {
            ICM marc = ICM(CMaddy);
            IV3 v3 = IV3(v3addy);
            require(v3.balanceOf(msg.sender) > 0 || marc.balanceOf(msg.sender) > 0);
            isAList[msg.sender] = true;
        }
        function aListByOwner(address alist) public onlyOwner {
            isAList[alist] = true;
        }
    //mint wifey function for allowlist and public sale
    function mintWifeys(uint256 amount) public payable whenMintActive {
        require(amount > 0 && amount <= 69, "Invalid token count");
        require(mintedWifeys + amount < maxWifeys, "More than available supply");
        if (publicMintOn) {
            require(amount * mintPrice == msg.value, "Incorrect amount of ether sent");
            _mintRandom(msg.sender, amount);
            mintSuccess = true;
            walletMinted[msg.sender] += amount;
            } else if (aListMintOn) {
                if ((phreeWifeyMints < maxPhree && this.balanceOf(msg.sender) < 1)) {
                    require(amount == maxPhreePerWallet, "First one's on the house! Please mint one for free");
                    require(amount * Phree == msg.value, "First one's on the house! Please mint one for free");
                    ICM marc = ICM(CMaddy);
                    IV3 v3 = IV3(v3addy);
                    require(v3.balanceOf(msg.sender) > 0 || marc.balanceOf(msg.sender) > 0 || isAList[msg.sender] == true, "Plese wait for public mint");
                    phreeWifeyMints += amount;
                } else {
                    require(amount * mintPrice == msg.value, "Incorrect amount of eth sent, please send 0.0069 eth per wifey");
                    ICM marc = ICM(CMaddy);
                    IV3 v3 = IV3(v3addy);
                    require(v3.balanceOf(msg.sender) > 0 || marc.balanceOf(msg.sender) > 0 || isAList[msg.sender] == true, "Please wait for public mint");
                } 
                _mintRandom(msg.sender, amount);
                mintSuccess = true;
                walletMinted[msg.sender] += amount;
            } else {
                mintSuccess = false;
                require(mintSuccess, "Mint failed!");
            }
    }
        //metadata URI
    string private _baseTokenURI;
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
    //withdraw to contract deployer
    function withdraw() external onlyOwner {
            (bool success,) = msg.sender.call{value : address(this).balance}("");
            require(success, "Withdrawal failed");
        }
}