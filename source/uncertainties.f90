!Copyright (C) 2013- Roger Wesson
!Free under the terms of the GNU General Public License v3

module mod_uncertainties
use mod_types
use mod_quicksort

contains

subroutine get_uncertainties(fittedspectrum, realspec, fittedlines)

  implicit none

  type(spectrum), dimension(:), allocatable :: realspec, fittedspectrum
  type(linelist), dimension(:), allocatable :: fittedlines
  real, dimension(:), allocatable :: residuals
  real, dimension(20) :: spectrumchunk
  real :: wavelengthsampling
  integer :: i, uncertaintywavelengthindex

#ifdef CO
  print *,"subroutine: get_uncertainties"
#endif

  allocate(residuals(size(realspec)))

  residuals=realspec%flux - fittedspectrum%flux

! in a moving 20 unit window, calculated the RMS of the residuals, excluding the
! 2 largest (this avoids the uncertainty calculation being biased by unfitted
! lines or large residuals from the wings of lines)

  do i=10,size(realspec)-10
    spectrumchunk=abs(residuals(i-9:i+10))
    call qsort(spectrumchunk)
    realspec(i)%uncertainty=(sum(spectrumchunk(1:18)**2)/18.)**0.5
  enddo

! fill in the ends with the closest calculated values

  realspec(1:10)%uncertainty=realspec(11)%uncertainty
  realspec(size(realspec%uncertainty)-10:size(realspec%uncertainty))%uncertainty=realspec(size(realspec%uncertainty)-11)%uncertainty

! determine uncertainty for each line from ratio of peak flux to rms at wavelength of line, using relation from Lenz & Ayres, 1992, PASP, 104, 1104
! wavelength sampling determined at location of line. this would break if a line peak is in the last pixel of the spectrum, should add something to prevent this as it would only have half the profile to fit from anyway in that case.

  do i=1,size(fittedlines%uncertainty)
    uncertaintywavelengthindex=minloc(abs(realspec%wavelength-fittedlines(i)%wavelength),1)
    if (realspec(uncertaintywavelengthindex)%uncertainty .ne. 0.d0) then
      wavelengthsampling = realspec(uncertaintywavelengthindex+1)%wavelength - realspec(uncertaintywavelengthindex)%wavelength
      fittedlines(i)%uncertainty=0.67*(fittedlines(i)%wavelength/(fittedlines(i)%resolution*wavelengthsampling))**0.5&
      &*fittedlines(i)%peak/realspec(uncertaintywavelengthindex)%uncertainty
    else
      fittedlines(i)%uncertainty=0.d0
    endif
  enddo

end subroutine get_uncertainties

end module mod_uncertainties
