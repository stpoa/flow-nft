import CrazyCats from "../contracts/CrazyCats.cdc"

pub fun main(acct: Address): [UInt64] {
  let publicRef = getAccount(acct).getCapability(CrazyCats.CollectionPublicPath)
            .borrow<&CrazyCats.Collection{CrazyCats.CrazyCatsCollectionPublic}>()
            ?? panic ("Oof ouch owie this account doesn't have a collection there")

  return publicRef.getIDs()
}
