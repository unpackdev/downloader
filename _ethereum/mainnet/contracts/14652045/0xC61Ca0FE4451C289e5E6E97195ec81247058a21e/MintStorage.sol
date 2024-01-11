// SPDX-License-Identifier: MIT
pragma solidity =0.6.12;

import "./MintLogic.sol";
import "./IChiGasToken.sol";
import "./MintLogicProxy.sol";

contract MintStorage is Initializable {
    using Address for address;

    address public owner;
    address public logicAddr;
    address[] public mintProxys;

    bool public paidUse;
    bool public gasOptimization = true;
    IChiGasToken public chiGasToken = IChiGasToken(0x0000000000004946c0e9F43F4Dee607b0eF1fA1c);

    constructor() public initializer {}

    modifier onlyOwner() {
        require(owner == msg.sender, "MintProxy: caller is not the owner");
        _;
    }

    modifier optimization() {
        if(gasOptimization){
            uint u1 = gasleft();
            _;
            uint u2 = gasleft();
            chiGasToken.freeFromUpTo(tx.origin, (u1 - u2) / 24000);
        }else {
            _;
        }
    }

    modifier paid() {
        if(paidUse){
            createProxys(1);
        }
        _;
    }

    function initialize() public initializer {
        owner = msg.sender;
    }

    function setPaidUse(bool _paidUse) external onlyOwner {
        paidUse = _paidUse;
    }

    function setLogicAddr(address _logicAddr) external onlyOwner {
        logicAddr = _logicAddr;
    }

    function setGasOptimization(bool _gasOptimization) external onlyOwner {
        gasOptimization = _gasOptimization;
    }

    function createProxys(uint256 _quantity) public {
        for(uint i = 0; i < _quantity; i++){
            MintLogicProxy mintProxy = new MintLogicProxy(logicAddr, address(this), abi.encodeWithSignature("initialize(address)", address(this)));
            mintProxys.push(address(mintProxy));
        }
    }

    function getProxySize() public view returns(uint256) {
        return mintProxys.length;
    }

    function execute(uint256 _start, uint256 _end, address _contolAddr, address _nftAddr, uint256 _price, bytes memory _data) external payable optimization paid {
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

    function fetchNft(address _nftAddr, uint256[] memory _tokenIds) external optimization paid {
        IERC721Enumerable nft = IERC721Enumerable(_nftAddr);
        for(uint i = 0; i < _tokenIds.length; i++){
            address nftOwner = nft.ownerOf(_tokenIds[i]);
            if (nftOwner.isContract()) {
                try MintLogic(nftOwner).fetchNft(_nftAddr, _tokenIds[i]) {
                    continue;
                } catch {
                    break;
                }
            }
        }
    }

    function fetchNft(address _nftAddr, uint256 _startId, uint256 _quantity) external optimization paid {
        IERC721Enumerable nft = IERC721Enumerable(_nftAddr);
        for(uint i = _startId; i < _startId + _quantity; i++){
            address nftOwner = nft.ownerOf(i);
            if (nftOwner.isContract()) {
                try MintLogic(nftOwner).fetchNft(_nftAddr, i) {
                    continue;
                } catch {
                    break;
                }
            }
        }
    }

}