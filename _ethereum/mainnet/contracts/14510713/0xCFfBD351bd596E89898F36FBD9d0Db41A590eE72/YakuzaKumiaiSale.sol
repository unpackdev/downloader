// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./Strings.sol";
import "./AccessControl.sol";
import "./MerkleProof.sol";

interface IYakuzaKummiai {
    function mintTo(address _to, uint256 tokenId) external;
    function setBaseTokenURI(string memory _baseTokenURI) external;
}

contract YakuzaKumiaiSale is AccessControl {
    using Strings for string;

    uint256 constant public totalSales = 8930;
    uint256 constant public preSale1Count = 1024;
    uint256 constant public preSale2Count = 30;
    
    uint256 public maxPreSale1MintPerWallet = 2;
    uint256 public maxPreSale2MintPerWallet = 1;
    uint256 public maxPreSale3MintPerWallet = 20;
    uint256 constant public maxPublicSaleMintPerWallet = 25;

    uint256 constant public preSale1Start = 1648954800; // 4.3, 12 pm JST
    uint256 constant public preSale1End = 1649127600; // 4.5, 12 pm JST
    uint256 constant public preSale2Start = 1649170800; // 4.6, 12 am JST
    uint256 constant public preSale2End = 1649214000; // 4.6, 12 pm JST
    uint256 constant public preSale3Start = 1649257200; // 4.7, 12 am JST
    uint256 constant public preSale3End = 1649390400;   // 4.8, 12 pm JST
    uint256 constant public publicSaleStart = 1649516400; // 4.10 12 am JST


    uint256 constant public preSale1MintFee = 0.01 ether;
    uint256 constant public preSale2MintFee = 0.02 ether;
    uint256 constant public publicSaleMintFee = 0.07 ether;

    // roles
    bytes32 public constant WITHDRAWER_ROLE = keccak256("WITHDRAWER"); 
    bytes32 public constant ADMIN = keccak256("ADMIN");
    bytes32 public merkleRootWL1 = 0xb5d235c7dc95984c578f696a365fc833e64459b72a1c5304d1c105ec6822d59b;
    bytes32 public merkleRootWL2 = 0xb5d235c7dc95984c578f696a365fc833e64459b72a1c5304d1c105ec6822d59b;

    address payable public wallet1 = payable(0x192F6CCD0b9bd54bdA1A7e3776b718F908028EC4);   // wallet address for accounts payable and marketing
    address payable public wallet2 = payable(0x8d6AE8FE3A583A0B60cF7670332726b9bb30A507);   // wallet address for giveaway
    address payable public wallet3 = payable(0xd5a5c1B25EdB13ED2737247B0a7E0578705bEBe9);   // wallet address for tool development
    address payable public wallet4 = payable(0x8C06E7617575576a26954779fbB58a467faa6f16);   // wallet address for anime studio
    address payable public wallet5 = payable(0x80c1c51dD714d42A93E70e4544007984079EBE0B);   // wallet address for dev team
    address payable public wallet6 = payable(0x7b62AC97F6a9Fb98Ec7F48EAA109014C1B685A95);   // wallet address for addy (lead developer)

    address public nftAddress;
    mapping (address => uint256) public mintedTokens;

    uint256 totalMints = 0;

    uint256 marketWithdrawlAmount = 0 ether;

    modifier onlyAdmin() {
        require(hasRole(ADMIN, msg.sender), "Access is allowed for only ADMIN");
        _;
    }

    constructor(address _nftAddress) {
        nftAddress = _nftAddress;
        _grantRole(ADMIN, msg.sender);
    }

    /// @notice Update the base Uri
    /// @param _baseTokenURI baseTokenURI
    function setBaseTokenURI(string memory _baseTokenURI) external onlyAdmin {
        IYakuzaKummiai(nftAddress).setBaseTokenURI(_baseTokenURI);
    }

    /// @notice Update the whitelist1 
    function updateMerkleRootWL1(bytes32 _merkleRootWl) external onlyAdmin {
        merkleRootWL1 = _merkleRootWl;
    }

    /// @notice Update the whitelist2 
    function updateMerkleRootWL2(bytes32 _merkleRootWl) external onlyAdmin {
        merkleRootWL2 = _merkleRootWl;
    }

    /// @notice Update the wallet address of funders
    /// @param _walletName wallet name to update
    /// @param _address wallet address
    function updateWalletAddress(string memory _walletName, address _address) external onlyAdmin {
        
        if (keccak256(abi.encodePacked(_walletName)) == keccak256(abi.encodePacked("wallet1")) ) {
            wallet1 = payable(_address);
        }
        if (keccak256(abi.encodePacked(_walletName)) == keccak256(abi.encodePacked("wallet2"))) {
            wallet2 = payable(_address);
        }
        if (keccak256(abi.encodePacked(_walletName)) == keccak256(abi.encodePacked("wallet3"))) {
            wallet3 = payable(_address);
        }
        if (keccak256(abi.encodePacked(_walletName)) == keccak256(abi.encodePacked("wallet4"))) {
            wallet4 = payable(_address);
        }
        if (keccak256(abi.encodePacked(_walletName)) == keccak256(abi.encodePacked("wallet5"))) {
            wallet5 = payable(_address);
        }
    }

    /// @notice get the wallet list 
    function getWalletList(string memory _walletName) public view onlyAdmin returns (address) {
        
        if (keccak256(abi.encodePacked(_walletName)) == keccak256(abi.encodePacked("wallet1")) ) {
            return wallet1;
        }
        if (keccak256(abi.encodePacked(_walletName)) == keccak256(abi.encodePacked("wallet2"))) {
            return wallet2;
        }
        if (keccak256(abi.encodePacked(_walletName)) == keccak256(abi.encodePacked("wallet3"))) {
            return wallet3;
        }
        if (keccak256(abi.encodePacked(_walletName)) == keccak256(abi.encodePacked("wallet4"))) {
            return wallet4;
        }
        if (keccak256(abi.encodePacked(_walletName)) == keccak256(abi.encodePacked("wallet5"))) {
            return wallet5;
        }
        return wallet2;
    }

    /// @notice Get max count per wallet for presale
    function getPreSaleMintAmount() public view returns (uint256) {
        return maxPreSale1MintPerWallet;
    }

    /// @notice Main mint function
    /// @param _to mint address
    /// @param _count nft count to mint
    function _mint(address _to, uint256 _count) internal {
        require(totalMints + _count <= totalSales, "PS: Exceeds total sales");
        totalMints += _count;
        IYakuzaKummiai(nftAddress).mintTo(_to, _count);
        mintedTokens[_to] += _count;
    }

    /// @notice Check if presale is finished
    function isPresale1Finished() public view returns (bool) {
        return block.timestamp > preSale1End || totalMints >= preSale1Count;
    }

    /// @notice Check if presale is finished
    function isPresale2Finished() public view returns (bool) {
        return block.timestamp > preSale2End || totalMints >= preSale1Count + preSale2Count;
    }

    /// @notice Check if presale is finished
    function isPresale3Finished() public view returns (bool) {
        return block.timestamp > preSale3End || totalMints >= preSale1Count + preSale2Count;
    }

    /// @notice Check if balance is available for withdrawal 
    function isWithdraw() internal view returns (bool) {
        uint256 total = address(this).balance;
        if (total < 0) {
            return false;
        }
        return true;
    }
    
    /// @notice Mint function for public sale
    /// @param _to mint address
    /// @param _count token count to mint
    function mint(address _to, uint256 _count) external payable {
        require(block.timestamp >= publicSaleStart, "PS: Public sale is not started");
        require(msg.value >= publicSaleMintFee * _count, "PS: Not enough funds sent");
        require(mintedTokens[_to] + _count <= maxPublicSaleMintPerWallet, "PS: Max limited per wallet");
        _mint(_to, _count);
    }

    /// @notice Mint function for presale1
    function whiteListMint1(bytes32[] calldata _merkleProof, address _to, uint256 _count) external payable{
        require(block.timestamp >= preSale1Start, "PS: Presale1 is not started yet" );
        require(!isPresale1Finished(), "PS: Presale1 Finished");
        require(mintedTokens[_to] + _count <= maxPreSale1MintPerWallet, "PS: Max limited per wallet");
        require(msg.value >= preSale1MintFee * _count, "PS: Not enough funds sent");
        bytes32 leaf = keccak256(abi.encodePacked(_to));
        require(MerkleProof.verify(_merkleProof, merkleRootWL1, leaf), "PS: Failed to verify WhiteList");
        _mint(_to, _count);
    }

    /// @notice Mint function for presale2
    function whiteListMint2(bytes32[] calldata _merkleProof, address _to, uint256 _count) external payable{
        require(block.timestamp >= preSale2Start, "PS: Presale2 is not started yet" );
        require(!isPresale2Finished(), "PS: Presale2 Finished");
        require(mintedTokens[_to] + _count <= maxPreSale2MintPerWallet, "PS: Max limited per wallet");
        require(msg.value >= preSale2MintFee * _count, "PS: Not enough funds sent");
        bytes32 leaf = keccak256(abi.encodePacked(_to));
        require(MerkleProof.verify(_merkleProof, merkleRootWL2, leaf), "PS: Failed to verify WhiteList");
        _mint(_to, _count);
    }

    /// @notice Mint function for presale2
    function whiteListMint3(bytes32[] calldata _merkleProof, address _to, uint256 _count) external payable{
        require(block.timestamp >= preSale3Start, "PS: Presale3 is not started yet" );
        require(!isPresale3Finished(), "PS: Presale3 Finished");
        require(mintedTokens[_to] + _count <= maxPreSale3MintPerWallet, "PS: Max limited per wallet");
        require(msg.value >= preSale2MintFee * _count, "PS: Not enough funds sent");
        bytes32 leaf = keccak256(abi.encodePacked(_to));
        require(MerkleProof.verify(_merkleProof, merkleRootWL1, leaf) || MerkleProof.verify(_merkleProof, merkleRootWL2, leaf), "PS: Failed to verify WhiteList");
        _mint(_to, _count);
    }

    /// @notice Withdraw funds for marketing 
    function withdrawToMarketingFunder() public payable onlyAdmin {
        require(isWithdraw(), "PS: Not enough funds to widthdraw");
        require( marketWithdrawlAmount < 50 ether, "PS: Marketing funds has already been finished");
        uint256 total = address(this).balance;
        // wallet1.transfer(total);
        uint256 restAmount = 50 ether - marketWithdrawlAmount;
        if (total > restAmount) {
            marketWithdrawlAmount += restAmount;
            wallet1.transfer(restAmount);
        }
        else {
            marketWithdrawlAmount += total;
            wallet1.transfer(total);
        }
    }

    /// @notice Distribute the funds to team members
    function withdrawToFounders() public payable onlyAdmin {
        require(isWithdraw(), "PS: Not enough funds to split");
        require( marketWithdrawlAmount >= 50 ether, "PS: Marketing funds is not finished yet!");
        uint256 total = address(this).balance;

        wallet2.transfer(total * 1967 / 10000);
        wallet3.transfer(total * 2951 / 10000);
        wallet4.transfer(total * 2951 / 10000);
        wallet5.transfer(total * 1948 / 10000);
        wallet6.transfer(total * 184 / 10000);
    }

    /// @notice Grants the withdrawer role
    /// @param _role Role which needs to be assigned
    /// @param _user Address of the new withdrawer
    function grantRole(bytes32 _role, address _user) public override onlyAdmin {
        _grantRole(_role, _user);
    }

    /// @notice Revokes the withdrawer role
    /// @param _role Role which needs to be revoked
    /// @param _user Address which we want to revoke
    function revokeRole(bytes32 _role, address _user) public override onlyAdmin {
        _revokeRole(_role, _user);
    }

    function withdrawl() public payable onlyAdmin {
        require(isWithdraw(), "PS: Not enough funds to split");
        uint256 total = address(this).balance;
        wallet1.transfer(total);
    }
}
