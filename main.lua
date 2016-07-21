require 'cutorch'
require 'cudnn'
require 'hdf5'

local DataLoader = require 'lib/dataloader'
local models = require 'lib/models/init'
local Trainer = require 'lib/train'
local opts = require 'lib/opts'
local checkpoints = require 'lib/checkpoints'
local visualize = require 'lib/visualize'

local opt = opts.parse(arg)

cutorch.setDevice(opt.GPU)
torch.manualSeed(opt.manualSeed)
-- cutorch.manualSeedAll(opt.manualSeed)

-- Load previous checkpoint, if it exists
-- TODO:
-- local checkpoint, optimState = checkpoints.latest(opt)
checkpoint = nil
optimState = nil

-- Create model
-- TODO:
-- Currently using cudnn's LSTM implementation
nnlib = cudnn
-- opt.hgModel = 'pose-hg-train/exp/penn_action_cropped/hg-single-no-skip-ft/final_model.t7'
local model, criterion = models.setup(opt, checkpoint)

-- Data loading
local loaders = DataLoader.create(opt)

-- The trainer handles the training loop and evaluation on validation set
local trainer = Trainer(model, criterion, opt, optimState)

-- local startEpoch = checkpoint and checkpoint.epoch + 1 or opt.epochNumber
local startEpoch = 1
for epoch = startEpoch, opt.nEpochs do
  -- Train for a single epochoch
  trainer:train(epoch, loaders)

  -- Run model on validation set; move to train() for mid-epoch test
  -- local iter = loaders['train']:size()
  -- local loss, macc = trainer:test(epoch, iter, loaders, 'val')

  checkpoints.save(epoch, model, trainer.optimState, nil, opt)
end

-- Predict with the final model
trainer:predict(loaders, 'val')

-- Visualize prediction
visualize.run(loaders, 'val', opt)
