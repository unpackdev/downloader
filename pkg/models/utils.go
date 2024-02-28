package models

import (
	"encoding/base64"
	"math/big"
)

func DecodeCursor(encodedCursor string) (*big.Int, error) {
	decodedBytes, err := base64.URLEncoding.DecodeString(encodedCursor)
	if err != nil {
		return nil, err // Return an error if the cursor can't be decoded
	}

	// Create a big.Int instance and attempt to decode the bytes into it
	decoded := new(big.Int)
	if err := decoded.GobDecode(decodedBytes); err != nil {
		return nil, err // Return an error if GobDecode fails
	}

	return decoded, nil
}
