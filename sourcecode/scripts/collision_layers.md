# Layers
- Layer 1: World
- Layer 2: Creature
- Layer 3: Item


# Player (CharacterBody2D)
- Layer: 2 (Creature)
- Mask: 1, 2 (World, Creature)
  
## DetectionArea => collect items
- Layer: -
- Mask: 1 (Item)




# TRex (CharacterBody2D)
- Layer: 2 (Creature)
- Mask: 1, 2  (World, Creature)

## DetectionArea
- Layer: -
- Mask: 2 (Creature)
  
## DamageArea
- Layer: -
- Mask: 2 (Creature)



# Brontosaurus (CharacterBody2D)
- Layer: 2 (Creature)
- Mask: 1, 2 (World, Creature)

## InteractionArea
- Layer: -
- Mask: 2 (Creature)
  
## DamageArea
- Layer: -
- Mask: 2 (Creature)

  
# Item (Area2D)
- Layer: 3 (Item)
