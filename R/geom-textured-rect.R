#' Textured rectangles
#'
#' `geom_textured_rect()` draws rectangles that are filled with
#' texture images.
#' @inheritParams ggplot2::geom_raster
#' @inheritParams texture_grob
#' @examples
#' library(ggplot2)
#' library(tibble)
#' library(magick)
#'
#' data <- tibble(
#'   xmin = c(1, 2.5), ymin = c(1, 1), xmax = c(2, 4), ymax = c(4, 3),
#'   image = list(
#'     "https://jeroen.github.io/images/Rlogo.png",
#'     image_read_svg("https://jeroen.github.io/images/tiger.svg")
#'    )
#' )
#'
#' ggplot(data, aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax, image = image)) +
#'   geom_textured_rect(img_width = unit(1, "in"))
#' @export
geom_textured_rect <- function(mapping = NULL, data = NULL,
                               stat = "identity", position = "identity",
                               ...,
                               img_width = unit(1, "null"), img_height = NA,
                               nrow = NA, ncol = NA,
                               na.rm = FALSE,
                               show.legend = NA,
                               inherit.aes = TRUE) {
  layer(
    data = data,
    mapping = mapping,
    stat = stat,
    geom = GeomTexturedRect,
    position = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params = list(
      na.rm = na.rm,
      img_width = img_width,
      img_height = img_height,
      nrow = nrow,
      ncol = ncol,
      ...
    )
  )
}

#' @rdname geom_textured_rect
#' @format NULL
#' @usage NULL
#' @export
GeomTexturedRect <- ggproto("GeomTexturedRect",
  Geom,
  default_aes = aes(
    colour = "black", fill = "grey85", size = 0.5, linetype = 1, alpha = NA,
    hjust = 0.5, vjust = 0
  ),

  required_aes = c("xmin", "xmax", "ymin", "ymax", "image"),

  draw_panel = function(self, data, panel_params, coord,
                        img_width = unit(1, "null"), img_height = NA,
                        nrow = NA, ncol = NA) {
    if (!coord$is_linear()) {
      warning("geom_textured_rect() does not work with nonlinear coords", call. = FALSE)
    } else {
      coords <- coord$transform(data, panel_params)
      coords$image <- unlist(coords$image)

      # calculate x and y deltas in transformed coordinates,
      # in case they are needed
      df <- coord$transform(
        data.frame(xmin = 0, xmax = 1, ymin = 0, ymax = 1),
        panel_params
      )
      dx <- df$xmax - df$xmin
      dy <- df$ymax - df$ymin

      iw <- img_width
      ih <- img_height

      grobs <- pmap(
        coords,
        function(xmin, xmax, ymin, ymax, image, hjust, vjust, colour, alpha, fill,
                 size, linetype, ...) {

          # native coordinates need to be transformed appropriately
          if (is_native_unit(img_width)) {
            iw <- unit(c(img_width)*dx/(xmax - xmin), "null")
          }
          if (is_native_unit(img_height)) {
            ih <- unit(c(img_height)*dy/(ymax - ymin), "null")
          }

          texture_grob(
            get_raster_image(image),
            x = unit(xmin, "native"), y = unit(ymax, "native"),
            width = unit(xmax - xmin, "native"),
            height = unit(ymax - ymin, "native"),
            img_width = iw,
            img_height = ih,
            nrow = nrow,
            ncol = ncol,
            hjust = hjust,
            vjust = vjust,
            just = c(0, 1),
            color = colour,
            fill = scales::alpha(fill, alpha),
            lwd = size * .pt,
            lty = linetype
          )
        }
      )
      do.call(gList, grobs)
    }
  },

  draw_key = draw_key_texture
)

get_raster_image <- function(img) {
  UseMethod("get_raster_image", img)
}

get_raster_image.default <- function(img) {
  magick::image_read(img)
}

`get_raster_image.magick-image` <- function(img) {
  img
}

# sources of free textures to use:
# https://www.hypergridbusiness.com/free-seamless-textures/
# (CC0 license)
#
# http://www.wildtextures.com/
# (free for use, can't be redistributed)
#
# http://www.cadhatch.com/seamless-textures/4588167680
