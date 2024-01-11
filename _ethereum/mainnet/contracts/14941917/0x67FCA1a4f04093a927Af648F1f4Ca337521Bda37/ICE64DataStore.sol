// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

/*


        .++++++    .-=+**++=:  -+++++++++++-      .-=+**.     .++++:      
         :@@@@. .+%@#++++#@@@@#=*@@@%++*@@@*   :*@@%+=-:      +@@@+       
          %@@# +@@+        :#@@#.@@@=    :#+ .#@@*.          -@@@+        
          #@@#*@@=           *@# @@@@-      -@@@*+*+=-      :@@@= =       
          #@@@@@@             += @@@@@@%%%=:@@@@*++#@@@#:  :@@@--%#       
          #@@@@@@                @@@= -*@@=#@@@     .*@@@--@@# +@@#   =   
          #@@@@@@-               @@@=    :.@@@%       #@@@@@+..+@@%-*@@   
          #@@#%@@@-           .%@@@@=      #@@@:      -@@@@@@@@@@@@@@@@   
          %@@# #@@@#-       :+@%-@@@=     :%@@@%.     *@@+     +@@%       
         :@@@@. :*@@@@%###%@@#= +@@@#++#%@@@**@@@#=-=%@%-     .@@@@-      
        .*****+    :=*###*+-.  -************:  -*###*=:      :******=

        D A T A   S T O R A G E   C O N T R A C T

*/

import "./Owned.sol";
import "./SSTORE2.sol";

import "./IICE64.sol";
import "./IICE64DataStore.sol";

/**
@title ICE64 data store
@author Sam King (samkingstudio.eth)
@notice Stores the on-chain image data for ICE64 editions. Images are in the Exquisite Graphics
        format (.xqst) for use by the rendering smart contract.

        Code is licensed as MIT.
        https://spdx.org/licenses/MIT.html

        Token metadata and images licensed as CC BY-NC 4.0
        https://creativecommons.org/licenses/by-nc/4.0/
        You are free to:
            - Share: copy and redistribute the material in any medium or format
            - Adapt: remix, transform, and build upon the material
        Under the following terms:
            - Attribution: You must give appropriate credit, provide a link to the license,
            and indicate if changes were made. You may do so in any reasonable manner, but not
            in any way that suggests the licensor endorses you or your use.
            - NonCommercial: You may not use the material for commercial purposes
            - No additional restrictions: You may not apply legal terms or technological measures
            that legally restrict others from doing anything the license permits.

*/
contract ICE64DataStore is IICE64DataStore, Owned {
    /* ------------------------------------------------------------------------
                                   S T O R A G E
    ------------------------------------------------------------------------ */

    string private _originalsBaseURI;
    uint256 private constant _photoDataByteSize = 4360;
    uint256 private constant _photoDataChunkLength = 2;
    mapping(uint256 => address) private _photoDataChunks;

    /* ------------------------------------------------------------------------
                                    E R R O R S
    ------------------------------------------------------------------------ */

    /* ADMIN --------------------------------------------------------------- */

    error InvalidPhotoData();

    /* ------------------------------------------------------------------------
                                      I N I T
    ------------------------------------------------------------------------ */

    /// @param owner The owner of the contract upon deployment
    /// @param originalsBaseURI_ The base URI for original photos (usually arweave or ipfs)
    constructor(address owner, string memory originalsBaseURI_) Owned(owner) {
        _originalsBaseURI = originalsBaseURI_;
    }

    /* ------------------------------------------------------------------------
                         O F F - C H A I N   B A S E U R I
    ------------------------------------------------------------------------ */

    /// @notice Admin function to set the baseURI for original photos (arweave or ipfs)
    /// @param baseURI The new baseURI to set
    function setOriginalsBaseURI(string memory baseURI) external onlyOwner {
        _originalsBaseURI = baseURI;
    }

    /// @notice Retrieve the currently set baseURI
    /// @dev Used by the metadata contract to construct the tokenURI
    function getBaseURI() external view returns (string memory) {
        return _originalsBaseURI;
    }

    /* ------------------------------------------------------------------------
                          O N - C H A I N   S T O R A G E
    ------------------------------------------------------------------------ */

    /// @notice Admin function to store chunked photo data for on-chain editions
    /// @dev Stores the data in chunks for more efficient storage and costs
    /// @param chunkId The chunk id to save data for
    /// @param data The packed data in .xqst format
    function storeChunkedEditionPhotoData(uint256 chunkId, bytes calldata data) external onlyOwner {
        if (data.length != _photoDataByteSize * _photoDataChunkLength) revert InvalidPhotoData();
        _photoDataChunks[chunkId] = SSTORE2.write(data);
    }

    /// @notice Gets the raw .xqst data for a given photo
    /// @dev Used by the metadata contract to read data from storage
    /// @param id The id of the photo to get data for
    function getRawPhotoData(uint256 id) external view returns (bytes memory) {
        uint256 chunkId = ((id - 1) / _photoDataChunkLength) + 1;
        uint256 chunkIndex = (id - 1) % _photoDataChunkLength;
        uint256 startBytes = chunkIndex * _photoDataByteSize;
        return SSTORE2.read(_photoDataChunks[chunkId], startBytes, startBytes + _photoDataByteSize);
    }
}
