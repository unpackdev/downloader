// SPDX-License-Identifier: MIT
pragma solidity =0.6.12;

import "./MintLogic.sol";
import "./MintLogicProxy.sol";

contract MintStorage is Initializable {
    using Address for address;

    address public owner;
    address public logicAddr;
    address[] public mintProxys;

    constructor() public initializer {}

    modifier onlyOwner() {
        require(owner == msg.sender, "MintProxy: caller is not the owner");
        _;
    }

    function initialize() public initializer {
        owner = msg.sender;
    }

    function setLogicAddr(address _logicAddr) external onlyOwner {
        logicAddr = _logicAddr;
    }

    function createProxys(uint256 _quantity) external onlyOwner {
        for(uint i = 0; i < _quantity; i++){
            MintLogicProxy mintProxy = new MintLogicProxy(logicAddr, address(this), abi.encodeWithSignature("initialize(address)", address(this)));
            mintProxys.push(address(mintProxy));
        }
    }

    function execute(uint256 _start, uint256 _end, address _contolAddr, address _nftAddr, uint256 _price, bytes memory _data) external payable {
        for(uint i = _start; i < _end; i++){
            try MintLogic(mintProxys[i]).execute{value : _price}(_contolAddr, _nftAddr, _data) {
                continue;
            } catch {
                break;
            }
        }
        if(address(this).balance > 0) {
            msg.sender.transfer(address(this).balance);
        }
    }

    function fetchNft(address _nftAddr, uint256[] memory _tokenIds) external {
        IERC721Enumerable nft = IERC721Enumerable(_nftAddr);
        for(uint i = 0; i < _tokenIds.length; i++){
            address nftOwner = nft.ownerOf(_tokenIds[i]);
            if (nftOwner.isContract()) {
                try MintLogic(nftOwner).fetchNft(_nftAddr, _tokenIds[i]) {} catch {
                    continue;
                }
            }
        }
    }

    function fetchNft(address _nftAddr, uint256 _startId, uint256 _quantity) external {
        IERC721Enumerable nft = IERC721Enumerable(_nftAddr);
        for(uint i = _startId; i < _startId + _quantity; i++){
            address nftOwner = nft.ownerOf(i);
            if (nftOwner.isContract()) {
                try MintLogic(nftOwner).fetchNft(_nftAddr, i) {} catch {
                    continue;
                }
            }
        }
    }

}