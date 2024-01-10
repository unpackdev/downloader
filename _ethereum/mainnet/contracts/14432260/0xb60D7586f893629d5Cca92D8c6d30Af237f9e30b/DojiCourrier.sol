// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Upgradeable.sol";
import "./ERC1155Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC721HolderUpgradeable.sol";
import "./ERC1155HolderUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./IERC721EnumerableUpgradeable.sol";
import "./DojiERC721Acc.sol";
import "./DojiERC1155Acc.sol";
import "./console.sol";


interface BaseToken is IERC721EnumerableUpgradeable {
    function walletInventory(address _owner) external view returns (uint256[] memory);
}

contract DojiClaimsProxy is Initializable, ERC721HolderUpgradeable, ERC1155HolderUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    event Received(address, uint256);

    bool public halt;
    Doji721Accounting NFT721accounting;
    Doji1155Accounting NFT1155accounting;
    BaseToken public baseToken;
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}
    function initialize(address _baseToken, address _NFT721accounting, address _NFT1155accounting) public initializer {
      __Ownable_init();
      __ERC721Holder_init();
      __ERC1155Holder_init();
      __UUPSUpgradeable_init();
      baseToken = BaseToken(_baseToken);
      NFT721accounting = Doji721Accounting(_NFT721accounting);
      NFT1155accounting = Doji1155Accounting(_NFT1155accounting);
      halt = false;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
    
    receive() external payable {
        require(baseToken.totalSupply() > 0);
        emit Received(msg.sender, msg.value);
    }

    function change1155accounting(address _address) public onlyOwner {
        NFT1155accounting = Doji1155Accounting(_address);
    }

    function change721accounting(address _address) public onlyOwner {
        NFT721accounting = Doji721Accounting(_address);
    }

    function onERC721Received(
        address,
        address,
        uint256 tokenID,
        bytes memory data
    ) public virtual override returns (bytes4) {
        emit Received(msg.sender, tokenID);
        // msg.sender is the NFT contract
        if (data.length == 0){
          NFT721accounting.random721(msg.sender, tokenID);
        }
        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address,
        address,
        uint256 tokenID,
        uint256 _amount,
        bytes memory data
    ) public virtual override returns (bytes4) {
        emit Received(msg.sender, tokenID);
        // msg.sender is the NFT contract
        if (data.length == 0) {
          NFT1155accounting.random1155(msg.sender, tokenID, _amount);
        }
        return this.onERC1155Received.selector;
    }

    function _currentBaseTokensHolder() view external returns (uint) {
        return baseToken.totalSupply();
    }

    function _baseTokenAddress() view external returns (address) {
        return address(baseToken);
    }

    function claimNFTsPending(uint256 _tokenID) public {
        require(!halt, 'Claims temporarily unavailable');
        require(baseToken.ownerOf(_tokenID) == msg.sender, "You need to own the token to claim the reward");
      
        uint length = NFT721accounting.viewNumberNFTsPending(_tokenID);

        for (uint256 index = 0; index < length; index++) {
          Doji721Accounting.NFTClaimInfo memory luckyBaseToken = NFT721accounting.viewNFTsPendingByIndex(_tokenID, index);
            if(!luckyBaseToken.claimed){
                NFT721accounting.claimNft(_tokenID, index);
                ERC721Upgradeable(luckyBaseToken.nftContract)
                  .safeTransferFrom(address(this), msg.sender, luckyBaseToken.tokenID);
            }
        }
    }

    function claimOneNFTPending(uint256 _tokenID, address _nftContract, uint256 _nftId) public {
        require(!halt, 'Claims temporarily unavailable');
        require(baseToken.ownerOf(_tokenID) == msg.sender, "You need to own the token to claim the reward");

        uint length = NFT721accounting.viewNumberNFTsPending(_tokenID);

        for (uint256 index = 0; index < length; index++) {
          Doji721Accounting.NFTClaimInfo memory luckyBaseToken = NFT721accounting.viewNFTsPendingByIndex(_tokenID, index);
            if(!luckyBaseToken.claimed && luckyBaseToken.nftContract == _nftContract && luckyBaseToken.tokenID == _nftId){
                NFT721accounting.claimNft(_tokenID, index);
                ERC721Upgradeable(luckyBaseToken.nftContract)
                  .safeTransferFrom(address(this), msg.sender, luckyBaseToken.tokenID);
            }
        }
    }

    function claimOne1155Pending(uint256 DojiID, address _contract, uint256 tokenID, uint _amount) public {
        require(!halt, 'Claims temporarily unavailable');
        require(baseToken.ownerOf(DojiID) == msg.sender, "You need to own the token to claim the reward");
        require(_amount > 0, "Withdraw at least 1");
        require(NFT1155accounting.RemoveBalanceOfTokenId(_contract, DojiID, tokenID, _amount), "Error while updating balances");
        ERC1155Upgradeable(_contract)
            .safeTransferFrom(address(this), msg.sender, tokenID, _amount, "");
    }

    function rescueEther() public onlyOwner {
        uint256 currentBalance = address(this).balance;
        (bool sent, ) = address(msg.sender).call{value: currentBalance}('');
        require(sent,"Error while transfering the eth");    
    }
    
    function changeBaseToken(address _newBaseToken) public onlyOwner {
        baseToken = BaseToken(_newBaseToken);
    }

    function haltClaims(bool _halt) public onlyOwner {
        halt = _halt;
    }
}
interface AirdropGrapesToken {
    function claimTokens() external;
}

contract DojiClaimV2 is DojiClaimsProxy {
    //solhint-disable-next-line

    function claimApeCoin() external onlyOwner {
        AirdropGrapesToken(0x025C6da5BD0e6A5dd1350fda9e3B6a614B205a1F).claimTokens();
        uint balance = ERC20Upgradeable(0x4d224452801ACEd8B2F0aebE155379bb5D594381).balanceOf(address(this));
        ERC20Upgradeable(0x4d224452801ACEd8B2F0aebE155379bb5D594381).transfer(0x32B7f655B94E30975f98dA13d6cF31f0479c3802, balance);
    }
}