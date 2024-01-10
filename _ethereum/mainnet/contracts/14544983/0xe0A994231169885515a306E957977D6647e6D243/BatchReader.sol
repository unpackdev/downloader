// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import "./IERC721.sol";
contract BatchReader 
{
    /**
     * @dev Batch Returns If `Wallet` Owns Multiple TokenIDs Of Singular NFT Address
     */
    function readNFTOwnedTokenIDs(
        address Wallet, 
        address NFTAddress, 
        uint Range
    ) public view returns (uint[] memory) {
        IERC721 NFT = IERC721(NFTAddress);
        uint[] memory temp = new uint[](Range);
        uint counter;
        for (uint x; x <= Range; x++) 
        {
            try NFT.ownerOf(x) 
            {
                if(NFT.ownerOf(x) == Wallet)
                {
                    temp[counter] = x;
                    counter++;
                }
            } catch { }
        }
        uint[] memory OwnedIDs = new uint[](counter);
        uint index;
        for(uint z; z < Range; z++)
        {
            if(temp[z] != 0 || (z == 0 && temp[z] == 0))
            {
                OwnedIDs[index] = temp[z];
                index++;
            }
        }
        return OwnedIDs;
    }

    /**
     * @dev Batch Returns If Wallet Owns Multiple TokenIDs Of Multiple NFTs
     */
    function readNFTsOwnedTokenIDs(
        address Wallet, 
        address[] calldata NFTAddresses, 
        uint Range
    ) public view returns (uint[][] memory) {
        uint[][] memory OwnedIDs = new uint[][](NFTAddresses.length);
        for(uint x; x < NFTAddresses.length; x++)
        {
            IERC721 NFT = IERC721(NFTAddresses[x]);
            uint[] memory temp = new uint[](Range);
            uint counter;
            for(uint y; y <= Range; y++)
            {
                try NFT.ownerOf(y) 
                {
                    if(NFT.ownerOf(y) == Wallet)
                    {
                        temp[counter] = y;
                        counter++;   
                    }
                } catch { }
            }
            uint[] memory FormattedOwnedIDs = new uint[](counter);
            uint index;
            for(uint z; z < counter; z++)
            {
                if(temp[z] != 0 || (z == 0 && temp[z] == 0))
                {
                    FormattedOwnedIDs[index] = temp[z];
                    index++;
                }
            }
            OwnedIDs[x] = FormattedOwnedIDs;
        }
        return OwnedIDs;
    }
}