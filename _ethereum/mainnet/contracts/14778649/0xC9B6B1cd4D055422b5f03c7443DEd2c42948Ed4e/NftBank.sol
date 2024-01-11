// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC721.sol";
import "./ERC20.sol";
import "./Ownable.sol";

struct NFTProject {
    address contractAddress;
    address feeCollector;
    uint256 nftPrice;
    uint256  outFee;
    uint256  inFee;
}

contract NftBank is Ownable, ERC20 {
    mapping(address  => uint256[]) private NFTByProject;
    function getNFTbyProject(address ProjectID) public view returns ( uint256[] memory ) {
        return NFTByProject[ProjectID];
    }
    mapping(address  => NFTProject) public NFTProjectOf;
    mapping(address  => uint256) public bank;
    constructor() ERC20("NFT LIFE", "LIFE") {
        addNFTProject(NFTProject({
            contractAddress: 0x946b677Ff8725227008568C8A3eF66267482c097,
            feeCollector: msg.sender,
            nftPrice: 500 * 10 ** 18,
            outFee: 1000,
            inFee: 1000
        }));
    }
    uint256 public constant maxFee = 1000;
    function addNFTProject(NFTProject memory project) public onlyOwner {
        require (project.contractAddress != address(0),"updateNFTProjecFee: contractAddress 0 adress");
        require (NFTProjectOf[project.contractAddress].contractAddress == address(0),"addNFTProject: Project already exists");
        require (project.outFee <= maxFee, "addNFTProject: fee to high");
        require (project.inFee <= maxFee, "addNFTProject: fee to high");
        NFTProjectOf[project.contractAddress] = project;
    }
    function updateNFTProjectFee(NFTProject memory project) public onlyOwner {        
        require (project.contractAddress != address(0),"updateNFTProjecFee: contractAddress 0 adress");
        require (NFTProjectOf[project.contractAddress].contractAddress != address(0),"updateNFTProjecFee: Project don't exists");
        require (project.outFee <= maxFee, "updateNFTProjecFee: fee to high");
        require (project.inFee <= maxFee, "updateNFTProjecFee: fee to high");
        // price is fixed forever
        require (NFTProjectOf[project.contractAddress].nftPrice == project.nftPrice,"updateNFTProjecFee: you can NOT change nftPrice");
        NFTProjectOf[project.contractAddress] = project;
    }

    // project ID
    function mint(address ProjectID, uint256 NftID) public {
        NFTProject memory project = NFTProjectOf[ProjectID];
        require (project.contractAddress != address(0),"mint: Project not exists");
        // NFT PROJECT
        IERC721 NFT = IERC721(project.contractAddress);
        NFT.transferFrom(
            msg.sender,
            address(this),
            NftID
        );
        // project.inFee
        uint256 feeInToken = project.nftPrice / 10000 * project.inFee;
        if (feeInToken != 0) {
            _mint(project.feeCollector, feeInToken);
        }
        _mint(msg.sender, project.nftPrice - feeInToken);
        NFTByProject[ProjectID].push(NftID);
        bank[project.contractAddress] = bank[project.contractAddress] + 1;
    }

    function _redeem(address ProjectID, uint256 NftID, uint256 fee) private {
        NFTProject memory project = NFTProjectOf[ProjectID];
        require (project.contractAddress != address(0),"redeem: Project not exists");
        require (bank[project.contractAddress] > 0,"redeem: no NFTs for redeem");        
        require (balanceOf(msg.sender) >= project.nftPrice,"redeem: token balance exceeded");
        // NFT PROJECT
        IERC721 NFT = IERC721(project.contractAddress);
        NFT.safeTransferFrom(
            address(this),
            msg.sender,
            NftID
        );
        uint256 feeInToken = project.nftPrice / 10000 * fee;
        if (feeInToken != 0) {
            _transfer(
                msg.sender,
                project.feeCollector,
                feeInToken
            );
        }
        _burn(msg.sender, project.nftPrice - feeInToken);
        _remove_nft(ProjectID, NftID);
        bank[project.contractAddress] = bank[project.contractAddress] - 1;
    }
    function _remove_nft(address ProjectID, uint256 NftID) private {
        NFTByProject[ProjectID][NftID] = NFTByProject[ProjectID][NFTByProject[ProjectID].length - 1];
        NFTByProject[ProjectID].pop();
    }
    function redeem(address ProjectID, uint256 NftID) public {
        _redeem(ProjectID, NftID, NFTProjectOf[ProjectID].outFee);
    }
}
