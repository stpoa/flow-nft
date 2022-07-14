export const mintNFT = `
// REPLACE THIS WITH YOUR CONTRACT NAME + ADDRESS
import CrazyCats from 0x98cba20939aed408
// This remains the same 
import NonFungibleToken from 0x631e88ae7f1d7c20
import MetadataViews from 0x631e88ae7f1d7c20

transaction(
  recipient: Address,
  name: String,
  description: String,
  thumbnail: String,
) {
  prepare(signer: AuthAccount) {
    // Check if the user sending the transaction has a collection
    if signer.borrow<&CrazyCats.Collection>(from: CrazyCats.CollectionStoragePath) != nil {
        // If they do, we move on to the execute stage
        return
    }

    // If they don't, we create a new empty collection
    let collection <- CrazyCats.createEmptyCollection()

    // Save it to the account
    signer.save(<-collection, to: CrazyCats.CollectionStoragePath)

    // Create a public capability for the collection
    signer.link<&{NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection}>(
        CrazyCats.CollectionPublicPath,
        target: CrazyCats.CollectionStoragePath
    )
  }

  execute {
    let receiver = getAccount(recipient)
      .getCapability(CrazyCats.CollectionPublicPath)
      .borrow<&{NonFungibleToken.CollectionPublic}>()
      ?? panic("Could not get receiver reference to the NFT Collection") 

    CrazyCats.mintNFT(
      recipient: receiver,
      name: name,
      description: description,
      thumbnail: thumbnail
    )

    log("Minted an NFT and stored it into the collection")
  }
}
`;
