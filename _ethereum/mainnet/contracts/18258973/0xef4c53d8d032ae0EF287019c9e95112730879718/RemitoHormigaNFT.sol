// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./IERC20.sol";
import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";

contract RemitoHormigaNFT is ERC721Enumerable, ReentrancyGuard {
   struct Remito {
    uint256 valorDeclarado;
    uint256 recompensa;
    uint256 tiempoLimite;
    address liberatingWallet;
    string metadataURI;   
    string origen;
    string destino;
    bool entregado;
    bool refundClaimed;
}


    mapping(uint256 => Remito) public remitos;
    mapping(uint256 => address) public originalMinters;

    IERC20 public hormigaToken;

    uint256 public FEVPoolBalance;
    uint256 public FERPoolBalance;

    event Created(uint256 tokenId);
    event Delivered(uint256 tokenId);
    event RefundClaimed(uint256 tokenId, address minter);

    constructor(address _hormigaToken) ERC721("Remito Hormiga", "RHT") {
        hormigaToken = IERC20(_hormigaToken);
    }

    function mint(
    uint256 _valorDeclarado,
    uint256 _recompensa,
    uint256 _tiempoLimite,
    address _liberatingWallet,
    string memory _metadataURI,  // Cambio aquí: de _imageURI a _metadataURI
    string memory _origen,
    string memory _destino
) external nonReentrant {
        require(
            _liberatingWallet != address(0),
            "liberatingWallet no puede ser la direccion cero"
        );

        uint256 tokenId = totalSupply() + 1;

        Remito memory newRemito = Remito({
            valorDeclarado: _valorDeclarado,
            recompensa: _recompensa,
            tiempoLimite: _tiempoLimite,
            liberatingWallet: _liberatingWallet,
             metadataURI: _metadataURI,
            origen: _origen,
            destino: _destino,
            entregado: false,
            refundClaimed: false
        });

        remitos[tokenId] = newRemito;
        originalMinters[tokenId] = msg.sender;

        require(
            hormigaToken.transferFrom(msg.sender, address(this), _recompensa),
            "Failed to transfer to FERPool"
        );
        FERPoolBalance += _recompensa;

        require(
            hormigaToken.transferFrom(
                msg.sender,
                address(this),
                _valorDeclarado
            ),
            "Failed to transfer to FEVPool"
        );
        FEVPoolBalance += _valorDeclarado;

        _safeMint(msg.sender, tokenId);

        emit Created(tokenId);
    }

    function deliver(
        uint256 tokenId
    ) external nonReentrant onlyLiberatingWallet(tokenId) {
        Remito storage remito = remitos[tokenId];
        require(!remito.entregado, "Already delivered");
        address currentOwner = ownerOf(tokenId);

        require(
            FERPoolBalance >= remito.recompensa,
            "FERPoolBalance insufficient"
        );
        require(
            FEVPoolBalance >= remito.valorDeclarado,
            "FEVPoolBalance insufficient"
        );

        FERPoolBalance -= remito.recompensa;
        FEVPoolBalance -= remito.valorDeclarado;

        require(
            hormigaToken.transfer(
                currentOwner,
                remito.recompensa + remito.valorDeclarado
            ),
            "Failed to transfer from pools"
        );

        remito.entregado = true;

        emit Delivered(tokenId);
    }

    function claimRefund(
        uint256 tokenId
    ) external nonReentrant onlyLiberatingWallet(tokenId) {
        Remito storage remito = remitos[tokenId];

        require(!remito.entregado, "Already delivered");
        require(
            block.timestamp > remito.tiempoLimite,
            "Time limit not yet exceeded"
        );

        require(
            FERPoolBalance >= remito.recompensa,
            "FERPoolBalance insufficient"
        );
        require(
            FEVPoolBalance >= remito.valorDeclarado,
            "FEVPoolBalance insufficient"
        );

        FERPoolBalance -= remito.recompensa;
        FEVPoolBalance -= remito.valorDeclarado;

        require(
            hormigaToken.transfer(
                msg.sender,
                remito.recompensa + remito.valorDeclarado
            ),
            "Failed to transfer from pools"
        );

        remito.refundClaimed = true;

        emit RefundClaimed(tokenId, msg.sender);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
    return remitos[tokenId].metadataURI; 
    }

   

    function walletOfOwner(
        address _owner
    ) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function getNFTs(
        address account,
        string memory filter
    ) external view returns (uint256[] memory) {
        uint256 total = totalSupply();
        uint256[] memory filteredNFTs = new uint256[](total);
        uint256 counter = 0;

        for (uint256 i = 0; i < total; i++) {
            uint256 tokenId = i + 1;
            address tokenOwner = ownerOf(tokenId);
            bool isFilterMatch = false;

            if (
                keccak256(abi.encodePacked(filter)) ==
                keccak256(abi.encodePacked("own")) &&
                tokenOwner == account
            ) {
                isFilterMatch = true;
            } else if (
                keccak256(abi.encodePacked(filter)) ==
                keccak256(abi.encodePacked("created")) &&
                originalMinters[tokenId] == account
            ) {
                isFilterMatch = true;
            } else if (
                keccak256(abi.encodePacked(filter)) ==
                keccak256(abi.encodePacked("liberating")) &&
                remitos[tokenId].liberatingWallet == account &&
                !remitos[tokenId].entregado &&
                !remitos[tokenId].refundClaimed
            ) {
                isFilterMatch = true;
            } else if (
                keccak256(abi.encodePacked(filter)) ==
                keccak256(abi.encodePacked("finishedLiberating")) &&
                remitos[tokenId].liberatingWallet == account &&
                remitos[tokenId].entregado
            ) {
                isFilterMatch = true;
            } else if (
                keccak256(abi.encodePacked(filter)) ==
                keccak256(abi.encodePacked("refunded")) &&
                remitos[tokenId].refundClaimed
            ) {
                isFilterMatch = true;
            } else if (
                keccak256(abi.encodePacked(filter)) ==
                keccak256(abi.encodePacked("finishedHolder")) &&
                tokenOwner == account &&
                remitos[tokenId].entregado
            ) {
                isFilterMatch = true;
            }

            if (isFilterMatch) {
                filteredNFTs[counter] = tokenId;
                counter++;
            }
        }

        uint256[] memory result = new uint256[](counter);
        for (uint256 i = 0; i < counter; i++) {
            result[i] = filteredNFTs[i];
        }
        return result;
    }

    modifier onlyLiberatingWallet(uint256 tokenId) {
        require(
            msg.sender == remitos[tokenId].liberatingWallet,
            "Not liberatingWallet"
        );
        _;
    }
}


//Libertad, libertad, libertad...

//Hormiga! Un viaje de ida...

//0xef4c53d8d032ae0EF287019c9e95112730879718