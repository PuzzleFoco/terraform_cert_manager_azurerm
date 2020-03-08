############################################################################
# Created Date: 23.10.2019                                                 #
# Author: Michael Süssemilch (michael.suessemilch@msg.group)               #
# -----                                                                    #
# Last Modified: 23.10.2019 09:28:28                                       #
# Modified By: Michael Süssemilch (michael.suessemilch@msg.group)          #
# -----                                                                    #
# Copyright (c) 2019 msg nexinsure ag                                      #
############################################################################

resources:
  requests:
    cpu: "${resources.requests.cpu}"
    memory: "${resources.requests.memory}"
  limits:
    cpu: "${resources.limits.cpu}"
    memory: "${resources.limits.memory}"