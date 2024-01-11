pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./ERC20.sol";
import "./Ownable.sol";

contract ClayToken is ERC20, IERC721Receiver, Ownable {
        address public nftAddress;
        uint256 tokenID;
        uint256 public baseRate = 1;
        uint256 public refRate = 50;
        uint256 public multRate = 10;
        address public burner;
        IERC721 collection;
        
        bool public paused = false;

        constructor() ERC20("Clay", "CLAY") public {
        }
    
        function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data ) public override returns (bytes4) {
            return this.onERC721Received.selector;
        }

        function bulkDeposit(address _NFTAddress, uint256[] memory _tokenIds, address referral) external {

            require(!paused);
            require(_NFTAddress!=referral);
            burner = msg.sender;
            collection = IERC721(_NFTAddress);

            for (uint256 i = 0; i < _tokenIds.length; i++) {
                collection.safeTransferFrom(burner, address(this), _tokenIds[i]);
            }
            _mint(burner, _tokenIds.length * multRate * baseRate * 10**uint(decimals()));
            _mint(referral, _tokenIds.length * multRate * baseRate* refRate /100 * 10**uint(decimals()));
            
        }

        function withdrawNFT(address _NFTAddress, uint256 _TokenID, address treasuryWallet)
            public onlyOwner
        {
            nftAddress = _NFTAddress;
            tokenID = _TokenID;
            IERC721(nftAddress).safeTransferFrom(address(this), treasuryWallet, tokenID);
        }

        function withdraw() public payable onlyOwner {
            payable(msg.sender).transfer(address(this).balance); 
        }
  
        function pause(bool _state) public onlyOwner {
            paused = _state;
        }
        

        function setBonus(uint256 _newRefRate) public onlyOwner {
            refRate = _newRefRate;
        }

        function setMult(uint256 _newMultRate) public onlyOwner {
            multRate = _newMultRate;
        }

        function setBase(uint256 _newBaseRate) public onlyOwner {
            baseRate = _newBaseRate;
        }

        function fundTreasury(address treasuryWallet, uint256 amt) public onlyOwner {
            _mint(treasuryWallet, amt * 10**uint(decimals()));
        }
 
       event ValueReceived(address user, uint amount);

       fallback() external payable {
            emit ValueReceived(msg.sender, msg.value);
       }

    
    }