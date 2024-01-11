// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./BaseERC721A.sol";
import "./SafeMath.sol";


contract AmazingNFT is BaseERC721A {
    using SafeMath for uint256;
    uint256 public constant MAX_SUPPLY = 10000;
    string private _baseTokenURI;
    address private _wallet = 0xC7BF7161A09Cf7123CB8983C5E35abE569344Bbd;
    
    constructor(string memory _tokenURI) ERC721A("AmazingNFT", "AMAZING", 4) {
        _baseTokenURI = _tokenURI;
    }

    // update token URI
    function updateMyTokenURI888(string memory tokenURI) external onlyOwner {
        _baseTokenURI = tokenURI;
    }
 
    // update wallet address
    function updateWalletAddress(address _address)
        external
        onlyOwner
    {
        _wallet = _address;
    }
    

    // airdrop NFT
    function airdropNFTDynamic(address[] calldata _address, uint256[] calldata _nums)
        external
        onlyOwner
    {
        
        uint256 sum = 0;
        for (uint i = 0; i < _nums.length; i++) {
            sum = sum + _nums[i];
        }
        
        require(
            sum  <= 1000,
            "Maximum 1000 tokens per transaction"
        );

        require(
            totalSupply() + sum <= MAX_SUPPLY,
            "Exceeds maximum supply"
        );

        for (uint256 i = 0; i < _address.length; i++) {
            _baseMint(_address[i], _nums[i]);
        }
    }

    
    // withdraw the balance if needed
    function withdraw() external onlyOwner {
        payable(_wallet).transfer(  address(this).balance );
    }

    // required override
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    // return the wallet address by index
    function walletAddress() external view returns (address) {
        return _wallet;
    }

}
